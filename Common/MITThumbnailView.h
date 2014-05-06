#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class MITThumbnailView;

@protocol MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data;

@end

DEPRECATED_ATTRIBUTE
@interface MITThumbnailView : UIView {
    NSString *imageURL;
    NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
    id<MITThumbnailDelegate> delegate;
}

- (void)loadImage;
- (void)requestImage;
+ (UIImage *)placeholderImage;

@property (nonatomic, assign) id<MITThumbnailDelegate> delegate;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
