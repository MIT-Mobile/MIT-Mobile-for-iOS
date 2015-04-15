#import <UIKit/UIKit.h>

@interface MITMobiusShopHeader : UITableViewHeaderFooterView

typedef NS_ENUM(NSInteger, MITMobiusShopStatus) {
    MITMobiusShopStatusClosed,
    MITMobiusShopStatusOpen,
    MITMobiusShopStatusUnknown
};

@property (nonatomic, copy) NSString *shopName;
@property (nonatomic, copy) NSString *shopHours;

+ (UINib *)searchHeaderNib;
+ (NSString *)searchHeaderNibName;
- (void)setStatus:(MITMobiusShopStatus)status;

@end
