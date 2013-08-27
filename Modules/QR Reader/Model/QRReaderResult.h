#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITScannerImage;

@interface QRReaderResult : NSManagedObject

@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) UIImage * thumbnail;
@property (nonatomic, copy) NSString * text;
@property (nonatomic, strong, readonly) UIImage * image;

@property (nonatomic, strong, readonly) MITScannerImage *imageData;
@property (nonatomic, strong) UIImage *scanImage;

+ (CGSize)defaultThumbnailSize;
@end
