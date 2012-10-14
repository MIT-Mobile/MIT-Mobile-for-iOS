#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "MITScannerImage.h"
#import "UIImage+Resize.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"

@interface QRReaderHistoryData ()
@end

@implementation QRReaderHistoryData
- (id)init {
    NSManagedObjectContext *context = [[[NSManagedObjectContext alloc] init] autorelease];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    
    return [self initWithManagedContext:context];
}

- (id)initWithManagedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self)
    {
        self.context = context;
    }
    
    return self;
}

- (void)dealloc {
    self.context = nil;
    [super dealloc];
}

- (void)deleteScanResult:(QRReaderResult*)result {
    [self.context deleteObject:result];
}

- (QRReaderResult*)insertScanResult:(NSString *)scanResult
                           withDate:(NSDate *)date {
    return [self insertScanResult:scanResult
                         withDate:date
                        withImage:nil];
}


- (QRReaderResult*)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image
{
    return [self insertScanResult:scanResult
                         withDate:date
                        withImage:image
          shouldGenerateThumbnail:NO];
}

- (QRReaderResult*)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image
            shouldGenerateThumbnail:(BOOL)generateThumbnail
{
    QRReaderResult *result = (QRReaderResult*)[NSEntityDescription insertNewObjectForEntityForName:@"QRReaderResult"
                                                                            inManagedObjectContext:self.context];
    result.text = scanResult;
    result.date = date;
    
    if (image)
    {
        image = [[UIImage imageWithCGImage:image.CGImage
                                    scale:1.0
                              orientation:UIImageOrientationUp] imageByRotatingImageInRadians:-M_PI_2];
        result.scanImage = image;
        
        if (generateThumbnail)
        {
            result.thumbnail =  [image resizedImage:[QRReaderResult defaultThumbnailSize]
                               interpolationQuality:kCGInterpolationDefault];
        }
    }
    
    return result;
}
@end
