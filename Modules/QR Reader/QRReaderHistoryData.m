#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "MITScannerImage.h"
#import "UIImage+Resize.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"

NSString * const kScannerHistoryLastOpenDateKey = @"scannerHistoryLastOpenDateKey";

@implementation QRReaderHistoryData
- (id)init {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
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

- (void)deleteScanResult:(QRReaderResult*)result {
    [self.context deleteObject:result];
}

- (void)deleteScanResults:(NSArray *)results
{
    for( QRReaderResult *result in results )
    {
        [self deleteScanResult:result];
    }
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

- (NSArray *)fetchRecentScans
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"QRReaderResult"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date >= %@", [self lastTimeHistoryWasOpened]];
    
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                   ascending:NO];
    fetchRequest.sortDescriptors = @[dateDescriptor];
    
    return[self.context executeFetchRequest:fetchRequest error:NULL];
}

- (void)persistLastTimeHistoryWasOpened
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kScannerHistoryLastOpenDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastTimeHistoryWasOpened
{
    NSDate * lastTimeHistoryWasOpened = [[NSUserDefaults standardUserDefaults] objectForKey:kScannerHistoryLastOpenDateKey];
    return (lastTimeHistoryWasOpened == nil ? [NSDate date] : lastTimeHistoryWasOpened);
}

@end
