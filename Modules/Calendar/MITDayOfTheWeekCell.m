#import "MITDayOfTheWeekCell.h"
#import "UIKit+MITAdditions.h"

@interface MITDayOfTheWeekCell ()

@property (weak, nonatomic) IBOutlet UILabel *dayOfTheWeekLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayOfTheMonthLabel;

@end

@implementation MITDayOfTheWeekCell

#pragma mark - Initialization

- (void)awakeFromNib
{
    self.dayOfTheMonthLabel.layer.cornerRadius = CGRectGetHeight(self.dayOfTheMonthLabel.bounds) / 2.0;
    self.dayOfTheMonthLabel.layer.masksToBounds = YES;
    self.dayOfTheMonthLabel.layer.shouldRasterize = YES;
    self.dayOfTheMonthLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

#pragma mark - Drawing

- (void)setDayOfTheWeek:(MITDayOfTheWeek)dayOfTheWeek
{
    _dayOfTheWeek = dayOfTheWeek;
    
    if (_dayOfTheWeek == MITDayOfTheWeekSaturday || _dayOfTheWeek == MITDayOfTheWeekSunday) {
        self.dayOfTheWeekLabel.textColor = [self lighterGrayColor];
        self.dayOfTheMonthLabel.textColor = [self lighterGrayColor];
    } else {
        self.dayOfTheWeekLabel.textColor = [UIColor darkTextColor];
        self.dayOfTheMonthLabel.textColor = [UIColor darkTextColor];
    }
    
    switch (_dayOfTheWeek) {
        case MITDayOfTheWeekSaturday:
        case MITDayOfTheWeekSunday:
            self.dayOfTheWeekLabel.text = @"S";
            break;
        case MITDayOfTheWeekMonday:
            self.dayOfTheWeekLabel.text = @"M";
            break;
        
        case MITDayOfTheWeekTuesday:
        case MITDayOfTheWeekThursday:
            self.dayOfTheWeekLabel.text = @"T";
            break;
            
        case MITDayOfTheWeekWednesday:
            self.dayOfTheWeekLabel.text = @"W";
            break;

        case MITDayOfTheWeekFriday:
            self.dayOfTheWeekLabel.text = @"F";
            break;
    }
}

- (void)setState:(MITDayOfTheWeekState)state
{
    _state = state;

    if ((state & MITDayOfTheWeekStateSelected) == MITDayOfTheWeekStateSelected && (state & MITDayOfTheWeekStateToday) == MITDayOfTheWeekStateToday) {
        // Is Selected && Is Today
        self.dayOfTheMonthLabel.textColor = [UIColor whiteColor];
        self.dayOfTheMonthLabel.backgroundColor = [UIColor mit_tintColor];
        self.dayOfTheMonthLabel.font = [UIFont boldSystemFontOfSize:17.0];
    } else if ((state & MITDayOfTheWeekStateUnselected) == MITDayOfTheWeekStateUnselected && (state & MITDayOfTheWeekStateToday) == MITDayOfTheWeekStateToday) {
        // Is Today && Not Selected
        self.dayOfTheMonthLabel.textColor = [UIColor mit_tintColor];
        self.dayOfTheMonthLabel.backgroundColor = [UIColor clearColor];
        self.dayOfTheMonthLabel.font = [UIFont systemFontOfSize:17.0];
    } else if ((state & MITDayOfTheWeekStateSelected) == MITDayOfTheWeekStateSelected) {
        // Is Selected && Not Today
        self.dayOfTheMonthLabel.textColor = [UIColor whiteColor];
        self.dayOfTheMonthLabel.backgroundColor = [UIColor darkTextColor];
        self.dayOfTheMonthLabel.font = [UIFont boldSystemFontOfSize:17.0];
    } else if ((state & MITDayOfTheWeekStateUnselected) == MITDayOfTheWeekStateUnselected) {
        // Is UnSelected && Not Today
        if (self.dayOfTheWeek == MITDayOfTheWeekSaturday || self.dayOfTheWeek == MITDayOfTheWeekSunday) {
            self.dayOfTheMonthLabel.textColor = [self lighterGrayColor];
        } else {
            self.dayOfTheMonthLabel.textColor = [UIColor darkTextColor];
        }
        self.dayOfTheMonthLabel.backgroundColor = [UIColor clearColor];
        self.dayOfTheMonthLabel.font = [UIFont systemFontOfSize:17.0];
    }
}

- (void)setDayOfTheMonth:(NSInteger)dayOfTheMonth
{
    _dayOfTheMonth = dayOfTheMonth;
    self.dayOfTheMonthLabel.text = [NSString stringWithFormat:@"%d", dayOfTheMonth];
}

#pragma mark - Lighter Text Color

- (UIColor *)lighterGrayColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}
@end
