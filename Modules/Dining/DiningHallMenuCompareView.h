#import <UIKit/UIKit.h>

@interface DiningHallMenuCompareView : UIView

@property (nonatomic, readonly, strong) UILabel * headerView;
@property (nonatomic, strong) NSDate *date;

- (void) resetScrollOffset;

@end
