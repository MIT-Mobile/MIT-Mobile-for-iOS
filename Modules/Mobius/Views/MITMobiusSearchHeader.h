#import <UIKit/UIKit.h>

@interface MITMobiusSearchHeader : UITableViewHeaderFooterView

@property (nonatomic, copy) NSString *shopName;
@property (nonatomic, copy) NSString *shopHours;
@property (nonatomic, copy) NSString *shopStatus;

+ (UINib *)searchHeaderNib;
+ (NSString *)searchHeaderNibName;

@end
