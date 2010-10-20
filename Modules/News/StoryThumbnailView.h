#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class NewsImageRep;

@interface StoryThumbnailView : UIView <ConnectionWrapperDelegate> {
    NewsImageRep *imageRep;
	ConnectionWrapper *connection;
	NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

@property (nonatomic, retain) NewsImageRep *imageRep;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
