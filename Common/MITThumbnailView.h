#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class MITThumbnailView;

@protocol MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data;

@end


@interface MITThumbnailView : UIView <ConnectionWrapperDelegate> {
    NSString *imageURL;
    ConnectionWrapper *connection;
    NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
    id<MITThumbnailDelegate> delegate;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;
+ (UIImage *)placeholderImage;

@property (nonatomic, assign) id<MITThumbnailDelegate> delegate;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
