#import <UIKit/UIKit.h>

@interface DiningHallMenuSectionHeaderView : UIView

@property (nonatomic, readonly, strong) UILabel       * mainLabel;
@property (nonatomic, readonly, strong) UILabel       * mealLabel;
@property (nonatomic, readonly, strong) UILabel       * timeLabel;

@property (nonatomic, assign) BOOL            showMealBar;
@property (nonatomic, strong) NSArray       * currentFilters;

@property (nonatomic, readonly, strong) UIButton * leftButton;
@property (nonatomic, readonly, strong) UIButton * rightButton;

+ (NSString *) stringForMeal:(NSDictionary *)meal onDate:(NSString *)dateString;

+ (CGFloat) heightForPagerBar;
+ (CGFloat) heightForFilterBar;
+ (CGFloat) heightForMealBar;

@end
