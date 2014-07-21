#import <UIKit/UIKit.h>
#import "MITNewsCustomWidthTableViewCell.h"
@class MITNewsStory;

@interface MITNewsStoryCell : MITNewsCustomWidthTableViewCell
@property (strong, nonatomic) MITNewsStory *story;

@property (weak, nonatomic) IBOutlet UIView *contentContainerView; // Can't call this 'contentView' because that conflicts with UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dekLabel;
@property (weak, nonatomic) IBOutlet UIImageView *storyImageView;

- (void)setRepresentedObject:(id)object;
@end
