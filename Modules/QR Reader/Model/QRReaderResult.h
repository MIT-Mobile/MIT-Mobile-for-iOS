#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITScannerImage;

@interface QRReaderResult : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) UIImage * thumbnail;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain, readonly) UIImage * image;

@property (nonatomic, readonly, retain) MITScannerImage *imageData;
@property (nonatomic, retain) UIImage *scanImage;

+ (CGSize)defaultThumbnailSize;
@end
