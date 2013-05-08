#import <UIKit/UIKit.h>

@class NewsImageRep;

@interface StoryThumbnailView : UIView {
    NewsImageRep *imageRep;
	NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

@property (nonatomic, retain) NewsImageRep *imageRep;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
