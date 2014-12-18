#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class QRReaderResult;

@interface QRReaderHistoryData : NSObject
@property (nonatomic,retain) NSManagedObjectContext *context;

- (id)initWithManagedContext:(NSManagedObjectContext*)context;

- (void)insertScanResult:(NSString*)scanResult
                withDate:(NSDate*)date
              completion:(void (^)(QRReaderResult* result, NSError *error))block;

- (void)insertScanResult:(NSString*)scanResult
                withDate:(NSDate*)date
               withImage:(UIImage*)image
              completion:(void (^)(QRReaderResult* result, NSError *error))block;

- (void)insertScanResult:(NSString*)scanResult
                withDate:(NSDate*)date
               withImage:(UIImage*)image
 shouldGenerateThumbnail:(BOOL)generateThumbnail
              completion:(void (^)(QRReaderResult* result, NSError *error))block;

- (QRReaderResult *)fetchScanResult:(NSManagedObjectID *)scanId;

- (void)deleteScanResults:(NSArray *)results completion:(void (^)(NSError* error))block;

- (void)resetHistoryNewScanCounter;
- (void)updateHistoryNewScanCounter;
- (NSInteger)historyNewScanCounter;

- (void)saveDataModelChanges;

@end
