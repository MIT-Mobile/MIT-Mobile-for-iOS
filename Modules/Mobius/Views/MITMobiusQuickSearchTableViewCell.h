#import <UIKit/UIKit.h>

@class MITMobiusResourceView;

@interface MITMobiusQuickSearchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;

+ (NSString *)quickSearchCellNibName;
+ (UINib *)quickSearchCellNib;

@end
