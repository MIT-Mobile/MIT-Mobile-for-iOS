#import <UIKit/UIKit.h>

@interface DiningHallMenuSectionHeaderView : UIView

@property (nonatomic, strong) NSDate        * date;
@property (nonatomic, strong) NSArray       * currentFilters;
@property (nonatomic, strong) NSDictionary  * meal;

@property (nonatomic, readonly, strong) UIButton * leftButton;
@property (nonatomic, readonly, strong) UIButton * rightButton;

@end
