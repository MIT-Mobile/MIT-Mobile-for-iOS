#import <UIKit/UIKit.h>

@interface MITMobiusDetailHeader : UITableViewHeaderFooterView

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;
@property (nonatomic,weak) IBOutlet UILabel *titleLabel;

@end
