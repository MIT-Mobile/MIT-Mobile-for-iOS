#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "MITScannerImage.h"
#import "UIImage+Resize.h"
#import "CoreDataManager.h"
#import "MITCoreDataController.h"
#import "UIKit+MITAdditions.h"

NSString * const kScannerHistoryNewScanCounterKey = @"kScannerHistoryNewScanCounterKey";

@implementation QRReaderHistoryData
- (id)init {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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

- (void)deleteScanResults:(NSArray *)results completion:(void (^)(NSError* error))block
{
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.context;
    [childContext performBlock:^{
        for( QRReaderResult *result in results )
        {
            @autoreleasepool
            {
                QRReaderResult *fetchedResult = (QRReaderResult *)[childContext objectWithID:result.objectID];
                [childContext deleteObject:fetchedResult];
            }
        }

        NSError *error;
        [childContext save:&error];
        
        if( block )
        {
            block( error );
        }
    }];
}

- (void)insertScanResult:(NSString *)scanResult
                withDate:(NSDate *)date
              completion:(void (^)(QRReaderResult* result, NSError *error))block
{
     [self insertScanResult:scanResult
                   withDate:date
                  withImage:nil
                 completion:block];
}


- (void)insertScanResult:(NSString*)scanResult
                withDate:(NSDate*)date
               withImage:(UIImage*)image
              completion:(void (^)(QRReaderResult *, NSError *))block
{
    [self insertScanResult:scanResult
                  withDate:date
                 withImage:image
   shouldGenerateThumbnail:NO
                completion:block];
}

// TODO: move to background
- (void)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image
            shouldGenerateThumbnail:(BOOL)generateThumbnail
                         completion:(void (^)(QRReaderResult* result, NSError *error))block
{
    QRReaderResult *result = (QRReaderResult*)[NSEntityDescription insertNewObjectForEntityForName:@"QRReaderResult"
                                                                            inManagedObjectContext:self.context];
    result.text = scanResult;
    result.date = date;
    
    if( image )
    {
        image = [UIImage imageWithCGImage:image.CGImage
                                     scale:1.0
                               orientation:UIImageOrientationUp];
        
        if( [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait ||
            [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown )
        {
            image = [image imageByRotatingImageInRadians:-M_PI_2];
        }

        result.scanImage = image;
        
        if (generateThumbnail)
        {
            result.thumbnail =  [image resizedImage:[QRReaderResult defaultThumbnailSize]
                                    interpolationQuality:kCGInterpolationDefault];
        }
    }
    
    NSError *error;
    [self.context save:&error];
    
    if( block )
    {
        block( result, error );
    }
}

- (QRReaderResult *)fetchScanResult:(NSManagedObjectID *)scanId
{
   return (QRReaderResult *)[self.context objectWithID:scanId];
}

- (void)updateHistoryNewScanCounter
{
    NSInteger currentCounter = [[NSUserDefaults standardUserDefaults] integerForKey:kScannerHistoryNewScanCounterKey];
    [[NSUserDefaults standardUserDefaults] setInteger:(++currentCounter) forKey:kScannerHistoryNewScanCounterKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetHistoryNewScanCounter
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kScannerHistoryNewScanCounterKey];
}

- (NSInteger)historyNewScanCounter
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kScannerHistoryNewScanCounterKey];
}

- (void)saveDataModelChanges
{
    if( [self.context hasChanges] )
    {
        NSError *saveError = nil;
        [self.context save:&saveError];
        if (saveError)
        {
            DDLogError(@"Error saving scan: %@", [saveError localizedDescription]);
        }
    }
}

@end
