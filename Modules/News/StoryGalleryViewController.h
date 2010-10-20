#import <UIKit/UIKit.h>
#import "StoryImageView.h"


@interface StoryGalleryViewController : UIViewController <StoryImageViewDelegate> {
    NSArray *images;
    NSInteger imageIndex;
    
    UIScrollView *scrollView;
    StoryImageView *storyImageView;
    UILabel *captionLabel;
    UILabel *creditLabel;
}

- (void)resizeLabelWithFixedWidth:(UILabel *)aLabel;
- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView;
- (void)didPressNavButton:(id)sender;
- (void)changeImage;

@property (nonatomic, retain) NSArray *images;

@end
