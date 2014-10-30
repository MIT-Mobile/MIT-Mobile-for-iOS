//
//  MITPadDayOfTheWeekCell.m
//  MIT Mobile
//
//  Created by Logan Wright on 10/30/14.
//
//

#import "MITPadDayOfTheWeekCell.h"
#import "UIKit+MITAdditions.h"

NSString * const MITPadDayOfTheWeekCellNibName = @"MITPadDayOfTheWeekCell";

@interface MITDayOfTheWeekCell ()

@property (weak, nonatomic) IBOutlet UILabel *dayOfTheWeekLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayOfTheMonthLabel;
- (UIColor *)lighterGrayColor;
@end

@implementation MITPadDayOfTheWeekCell

@synthesize dayOfTheWeek = _dayOfTheWeek, state = _state;

- (void)setDayOfTheWeek:(MITDayOfTheWeek)dayOfTheWeek
{
    _dayOfTheWeek = dayOfTheWeek;
    if (dayOfTheWeek == MITDayOfTheWeekSaturday || dayOfTheWeek == MITDayOfTheWeekSunday) {
        self.dayOfTheWeekLabel.textColor = [super lighterGrayColor];
        self.dayOfTheMonthLabel.textColor = [self lighterGrayColor];
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
    
    self.dayOfTheWeekLabel.text = dayOfTheWeekPrefix;
}

- (MITDayOfTheWeek)dayOfTheWeek
{
    return _dayOfTheWeek;
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

- (MITDayOfTheWeekState)state
{
    return _state;
}

@end
