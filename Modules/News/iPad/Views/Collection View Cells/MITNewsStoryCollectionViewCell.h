#import <UIKit/UIKit.h>
@class MITNewsStory;

@interface MITNewsStoryCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) MITNewsStory *story;

@property (weak, nonatomic) IBOutlet UIImageView *storyImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dekLabel;

@end

