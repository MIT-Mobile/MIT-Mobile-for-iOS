#import <UIKit/UIKit.h>
#import "Foundation+MITAdditions.h"

typedef NS_ENUM(NSInteger, MITDayOfTheWeekState) {
    MITDayOfTheWeekStateUnselected = 1,
    MITDayOfTheWeekStateSelected = 2,
    MITDayOfTheWeekStateToday = 4
};

typedef NS_ENUM(NSInteger, MITDayOfTheWeek) {
    MITDayOfTheWeekSunday,
    MITDayOfTheWeekMonday,
    MITDayOfTheWeekTuesday,
    MITDayOfTheWeekWednesday,
    MITDayOfTheWeekThursday,
    MITDayOfTheWeekFriday,
    MITDayOfTheWeekSaturday
};

@interface MITDayOfTheWeekCell : UICollectionViewCell

@property (nonatomic) MITDayOfTheWeek dayOfTheWeek;
@property (nonatomic) MITDayOfTheWeekState state;
@property (nonatomic) NSInteger dayOfTheMonth;

@end
