#import <UIKit/UIKit.h>

@class NewsImageRep;
@class StoryImageView;

@protocol StoryImageViewDelegate <NSObject>
@optional
- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView;
@end


@interface StoryImageView : UIView
@property (nonatomic, weak) id <StoryImageViewDelegate> delegate;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) NewsImageRep *imageRep;

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;

@end
