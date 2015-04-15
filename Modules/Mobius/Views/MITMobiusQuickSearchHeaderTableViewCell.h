#import <UIKit/UIKit.h>

@interface MITMobiusQuickSearchHeaderTableViewCell : UITableViewCell

+ (UINib *)quickSearchHeaderCellNib;
+ (NSString *)quickSearchHeaderCellNibName;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
