#import "MITDayOfTheWeekCell.h"
#import "UIColor+MITDatePicker.h"

NSString * const MITPhoneDayOfTheWeekCellNibName = @"MITPhoneDayOfTheWeekCell";
NSString * const MITPadDayOfTheWeekCellNibName = @"MITPadDayOfTheWeekCell";

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
    if (dayOfTheWeek == MITDayOfTheWeekSaturday || dayOfTheWeek == MITDayOfTheWeekSunday) {
        self.dayOfTheWeekLabel.textColor = [UIColor dp_lighterGrayTextColor];
        self.dayOfTheMonthLabel.textColor = [UIColor dp_lighterGrayTextColor];
    } else {
        self.dayOfTheWeekLabel.textColor = [UIColor darkTextColor];
        self.dayOfTheMonthLabel.textColor = [UIColor darkTextColor];
    }
    
    NSString *dayOfTheWeekPrefix;
    switch (_dayOfTheWeek) {
        case MITDayOfTheWeekSaturday:
            dayOfTheWeekPrefix = @"Sat";
            break;
        case MITDayOfTheWeekSunday:
            dayOfTheWeekPrefix = @"Sun";
            break;
        case MITDayOfTheWeekMonday:
            dayOfTheWeekPrefix = @"Mon";
            break;
        case MITDayOfTheWeekTuesday:
            dayOfTheWeekPrefix = @"Tue";
            break;
        case MITDayOfTheWeekThursday:
            dayOfTheWeekPrefix = @"Thu";
            break;
        case MITDayOfTheWeekWednesday:
            dayOfTheWeekPrefix = @"Wed";
            break;
        case MITDayOfTheWeekFriday:
            dayOfTheWeekPrefix = @"Fri";
            break;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        dayOfTheWeekPrefix = [dayOfTheWeekPrefix substringToIndex:1];
    }
    
    self.dayOfTheWeekLabel.text = dayOfTheWeekPrefix;
}

- (void)setState:(MITDayOfTheWeekState)state
{
    _state = state;

    if ((state & MITDayOfTheWeekStateSelected) == MITDayOfTheWeekStateSelected && (state & MITDayOfTheWeekStateToday) == MITDayOfTheWeekStateToday) {
        // Is Selected && Is Today
        self.dayOfTheMonthLabel.textColor = [UIColor whiteColor];
        self.dayOfTheMonthLabel.backgroundColor = self.selectionColor ? : [UIColor dp_selectionColor];
        self.dayOfTheMonthLabel.font = [UIFont boldSystemFontOfSize:17.0];
    } else if ((state & MITDayOfTheWeekStateUnselected) == MITDayOfTheWeekStateUnselected && (state & MITDayOfTheWeekStateToday) == MITDayOfTheWeekStateToday) {
        // Is Today && Not Selected
        self.dayOfTheMonthLabel.textColor = self.selectionColor ? : [UIColor dp_selectionColor];
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
            self.dayOfTheMonthLabel.textColor = [UIColor dp_lighterGrayTextColor];
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
    self.dayOfTheMonthLabel.text = [NSString stringWithFormat:@"%ld", (long)dayOfTheMonth];
}

@end
