#import <UIKit/UIKit.h>
#import "MITAutoSizingCell.h"

@class MITLibrariesWorldcatItem;

@interface MITLibrariesWorldcatItemCell : MITAutoSizingCell

// For subclasses
@property (nonatomic, weak) IBOutlet UILabel *itemTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *yearAndAuthorLabel;
@property (nonatomic, weak) IBOutlet UIImageView *itemImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *itemTitleLabelHorizontalTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *yearAndAuthorLabelHorizontalTrailingConstraint;
@property (nonatomic, assign) BOOL showsSeparator;

- (void)setContent:(MITLibrariesWorldcatItem *)item;

@end
