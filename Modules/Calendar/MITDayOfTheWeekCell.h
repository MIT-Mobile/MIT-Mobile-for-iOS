#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITDayOfTheWeek) {
    MITDayOfTheWeekSunday,
    MITDayOfTheWeekMonday,
    MITDayOfTheWeekTuesday,
    MITDayOfTheWeekWednesday,
    MITDayOfTheWeekThursday,
    MITDayOfTheWeekFriday,
    MITDayOfTheWeekSaturday
};

typedef NS_ENUM(NSInteger, MITDayOfTheWeekState) {
    MITDayOfTheWeekStateUnselected = 1,
    MITDayOfTheWeekStateSelected = 2,
    MITDayOfTheWeekStateToday = 4
};

@interface MITDayOfTheWeekCell : UICollectionViewCell

@property (nonatomic) MITDayOfTheWeek dayOfTheWeek;
@property (nonatomic) MITDayOfTheWeekState state;

@end
