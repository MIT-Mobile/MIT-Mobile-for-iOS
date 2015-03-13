#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITDayOfTheWeekState) {
    MITDayOfTheWeekStateUnselected = 1,
    MITDayOfTheWeekStateSelected = 2,
    MITDayOfTheWeekStateToday = 4
};

typedef NS_ENUM(NSInteger, MITDayOfTheWeek) {
    MITDayOfTheWeekSunday = 1,
    MITDayOfTheWeekMonday,
    MITDayOfTheWeekTuesday,
    MITDayOfTheWeekWednesday,
    MITDayOfTheWeekThursday,
    MITDayOfTheWeekFriday,
    MITDayOfTheWeekSaturday
};

extern NSString * const MITPhoneDayOfTheWeekCellNibName;
extern NSString * const MITPadDayOfTheWeekCellNibName;

@interface MITDayOfTheWeekCell : UICollectionViewCell

@property (strong, nonatomic) NSDate *date;
@property (nonatomic) MITDayOfTheWeek dayOfTheWeek;
@property (nonatomic) MITDayOfTheWeekState state;
@property (nonatomic) NSInteger dayOfTheMonth;
@property (strong, nonatomic) UIColor *todayColor;
@property (strong, nonatomic) UIColor *selectedDayColor;

@end
