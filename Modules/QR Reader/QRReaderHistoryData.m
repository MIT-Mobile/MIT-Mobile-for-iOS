#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "MITScannerImage.h"
#import "UIImage+Resize.h"
#import "CoreDataManager.h"
#import "MITCoreDataController.h"
#import "UIKit+MITAdditions.h"

NSString * const kScannerHistoryLastOpenDateKey = @"scannerHistoryLastOpenDateKey";

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

- (void)deleteScanResult:(QRReaderResult*)result completion:(void (^)(NSError* error))block
{
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
        [context deleteObject:[context objectWithID:result.objectID]];
        [context save:error];
    } completion:^(NSError *error) {
        if( block ) {
            block( error );
        }
    }];
}

- (void)deleteScanResults:(NSArray *)results completion:(void (^)(NSError* error))block
{
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
        for( QRReaderResult *result in results )
        {
            [context deleteObject:[context objectWithID:result.objectID]];
        }
        
        [context save:error];
        
    } completion:^(NSError *error) {
        if( block ) {
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

- (void)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image
            shouldGenerateThumbnail:(BOOL)generateThumbnail
                         completion:(void (^)(QRReaderResult* result, NSError *error))block
{
    __block UIImage *blockImage = image;
    
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
        
        QRReaderResult *result = (QRReaderResult*)[NSEntityDescription insertNewObjectForEntityForName:@"QRReaderResult"
                                                                                inManagedObjectContext:context];
        result.text = scanResult;
        result.date = date;
        
        if( blockImage )
        {
            blockImage = [[UIImage imageWithCGImage:blockImage.CGImage
                                              scale:1.0
                                        orientation:UIImageOrientationUp] imageByRotatingImageInRadians:-M_PI_2];
            result.scanImage = blockImage;
            
            if (generateThumbnail)
            {
                result.thumbnail =  [blockImage resizedImage:[QRReaderResult defaultThumbnailSize]
                                        interpolationQuality:kCGInterpolationDefault];
            }
        }
        
        [context save:error];
        
        if( block )
        {
            block( result, *error );
        }

    } completion:^(NSError *error) {
        if( block )
        {
            block( nil, error );
        }
    }];
}

- (QRReaderResult *)fetchScanResult:(NSManagedObjectID *)scanId
{
   return (QRReaderResult *)[self.context objectWithID:scanId];
}

- (NSArray *)fetchRecentScans
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"QRReaderResult"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date >= %@", [self lastTimeHistoryWasOpened]];
    
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
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
    NSDate *lastTimeHistoryWasOpened = [[NSUserDefaults standardUserDefaults] objectForKey:kScannerHistoryLastOpenDateKey];
    if ( lastTimeHistoryWasOpened == nil )
    {
        [self persistLastTimeHistoryWasOpened];
        
        return [NSDate date];
    }
    
    return lastTimeHistoryWasOpened;
}

- (void)saveDataModelChanges
{
    NSError *saveError = nil;
    [self.context save:&saveError];
    if (saveError)
    {
        DDLogError(@"Error saving scan: %@", [saveError localizedDescription]);
    }
}

@end
