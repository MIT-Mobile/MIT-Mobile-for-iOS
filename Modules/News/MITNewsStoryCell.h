#import <UIKit/UIKit.h>
@class MITNewsStory;

@interface MITNewsStoryCell : UITableViewCell
@property (strong, nonatomic) MITNewsStory *story;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dekLabel;
@property (weak, nonatomic) IBOutlet UIImageView *storyImageView;

- (void)setRepresentedObject:(id)object;
@end
