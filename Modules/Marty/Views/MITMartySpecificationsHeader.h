#import <UIKit/UIKit.h>

@interface MITMartySpecificationsHeader : UITableViewHeaderFooterView

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;
@property (nonatomic,weak) IBOutlet UILabel *titleLabel;

@end
