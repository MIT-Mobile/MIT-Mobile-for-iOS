#import <UIKit/UIKit.h>

@class MITImageGalleryViewController;

@protocol MITImageGalleryDataSource <NSObject>

- (NSInteger)numberOfImagesInGallery:(MITImageGalleryViewController *)galleryViewController;
- (NSURL *)gallery:(MITImageGalleryViewController *)gallery imageURLAtIndex:(NSInteger)index;

@end

@interface MITImageGalleryViewController : UIViewController

@property (nonatomic, weak) id<MITImageGalleryDataSource> dataSource;

@end
