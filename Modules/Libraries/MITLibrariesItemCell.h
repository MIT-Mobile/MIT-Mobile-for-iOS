#import <UIKit/UIKit.h>

@class MITLibrariesItem;

@interface MITLibrariesItemCell : UITableViewCell

// Set this to effect UI changes (label texts, image, etc)
@property (nonatomic, strong) MITLibrariesItem *item;

// For subclasses
@property (nonatomic, weak) IBOutlet UILabel *itemTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *yearAndAuthorLabel;
@property (nonatomic, weak) IBOutlet UIImageView *itemImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *itemTitleLabelHorizontalTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *yearAndAuthorLabelHorizontalTrailingConstraint;


+ (CGFloat)heightForItem:(MITLibrariesItem *)item tableViewWidth:(CGFloat)width;

@end
