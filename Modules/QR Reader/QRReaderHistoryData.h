#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class QRReaderResult;

@interface QRReaderHistoryData : NSObject
@property (nonatomic,retain) NSManagedObjectContext *context;

- (id)initWithManagedContext:(NSManagedObjectContext*)context;

- (QRReaderResult*)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date;

- (QRReaderResult*)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image;

- (QRReaderResult*)insertScanResult:(NSString*)scanResult
                           withDate:(NSDate*)date
                          withImage:(UIImage*)image
            shouldGenerateThumbnail:(BOOL)generateThumbnail;

- (QRReaderResult *)fetchScanResult:(NSManagedObjectID *)scanId;

- (void)deleteScanResult:(QRReaderResult*)result;
- (void)deleteScanResults:(NSArray *)results;

- (NSArray *)fetchRecentScans;

- (void)persistLastTimeHistoryWasOpened;

- (NSDate *)lastTimeHistoryWasOpened;

- (void)saveDataModelChanges;

@end
