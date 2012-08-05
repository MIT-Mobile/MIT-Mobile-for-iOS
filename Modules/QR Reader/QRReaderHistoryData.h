#import <Foundation/Foundation.h>

@class QRReaderResult;

@interface QRReaderHistoryData : NSObject

@property (nonatomic, retain) NSArray *results;
+ (QRReaderHistoryData*)sharedHistory;

+ (CGSize)defaultThumbnailSize;

- (void)eraseAll;

- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date;
- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date withImage:(UIImage*)image;
- (void)deleteScanResult:(QRReaderResult*)result;

@end
