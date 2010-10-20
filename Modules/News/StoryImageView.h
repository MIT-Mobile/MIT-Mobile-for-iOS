#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@class NewsImageRep;
@class StoryImageView;

@protocol StoryImageViewDelegate <NSObject>
@optional
- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView;
@end


@interface StoryImageView : UIView <ConnectionWrapperDelegate> {
    id <StoryImageViewDelegate> delegate;
    NewsImageRep *imageRep;
	ConnectionWrapper *connection;
	NSData *imageData;
    UIActivityIndicatorView *loadingView;
    UIImageView *imageView;
}

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

@property (nonatomic, assign) id <StoryImageViewDelegate> delegate;
@property (nonatomic, retain) NewsImageRep *imageRep;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) UIActivityIndicatorView *loadingView;
@property (nonatomic, retain) UIImageView *imageView;

@end
