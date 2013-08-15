#import <UIKit/UIKit.h>

@class NewsImageRep;

@interface StoryThumbnailView : UIView
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) NewsImageRep *imageRep;

- (void)loadImage;
- (void)requestImage;
- (BOOL)displayImage;
@end
