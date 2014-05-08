#import <UIKit/UIKit.h>

@class MITThumbnailView;

@protocol MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data;

@end

DEPRECATED_ATTRIBUTE
@interface MITThumbnailView : UIView
- (void)loadImage;
- (void)requestImage;
+ (UIImage *)placeholderImage;

@property (nonatomic, assign) id<MITThumbnailDelegate> delegate;
@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, copy) NSData *imageData;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIImageView *imageView;

@end
