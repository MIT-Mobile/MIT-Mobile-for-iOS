#import <UIKit/UIKit.h>
#import "StoryImageView.h"


@interface StoryGalleryViewController : UIViewController <StoryImageViewDelegate>
@property (copy) NSArray *images;

- (void)resizeLabelWithFixedWidth:(UILabel *)aLabel;
- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView;
- (void)didPressNavButton:(id)sender;
- (void)changeImage;

@end
