#import <UIKit/UIKit.h>

@interface MITMobiusSpecificationsHeader : UITableViewHeaderFooterView

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;
@property (nonatomic,weak) IBOutlet UILabel *titleLabel;

@end
