#import <UIKit/UIKit.h>

@interface MITDisclosureHeaderView : UITableViewHeaderFooterView
@property (nonatomic,weak) IBOutlet UILabel *titleLabel;
@property (nonatomic,weak) IBOutlet UIView *accessoryView;
@property (nonatomic,weak) IBOutlet UIView *containerView;

@property(nonatomic,getter=isHighlighted) BOOL highlighted;
@end
