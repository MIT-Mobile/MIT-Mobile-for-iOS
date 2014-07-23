#import <UIKit/UIKit.h>
#import "NSDate+MITAdditions.h"

typedef NS_ENUM(NSInteger, MITDayOfTheWeekState) {
    MITDayOfTheWeekStateUnselected = 1,
    MITDayOfTheWeekStateSelected = 2,
    MITDayOfTheWeekStateToday = 4
};

@interface MITDayOfTheWeekCell : UICollectionViewCell

@property (nonatomic) MITDayOfTheWeek dayOfTheWeek;
@property (nonatomic) MITDayOfTheWeekState state;

@end
