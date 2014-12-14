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

- (void)deleteScanResults:(NSArray *)results completion:(void (^)(NSError* error))block
{
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.context;
    [childContext performBlock:^{
        for( QRReaderResult *result in results )
        {
            [childContext deleteObject:[childContext objectWithID:result.objectID]];
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
