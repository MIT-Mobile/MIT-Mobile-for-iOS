#import "MITDayOfTheWeekCell.h"
#import "UIKit+MITAdditions.h"

@interface MITDayOfTheWeekCell ()

@property (weak, nonatomic) IBOutlet UILabel *dayOfTheWeekLabel;

@end

@implementation MITDayOfTheWeekCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setDayOfTheWeek:(MITDayOfTheWeek)dayOfTheWeek
{
    _dayOfTheWeek = dayOfTheWeek;
    
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
    
    self.dayOfTheWeekLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    
    if ((_state & MITDayOfTheWeekStateUnselected) == MITDayOfTheWeekStateUnselected) {
        self.dayOfTheWeekLabel.font = [UIFont systemFontOfSize:17.0];
    }
    
    if ((_state & MITDayOfTheWeekStateSelected) == MITDayOfTheWeekStateSelected) {
        self.dayOfTheWeekLabel.font = [UIFont boldSystemFontOfSize:17.0];
    }
    
    if ((_state & MITDayOfTheWeekStateToday) == MITDayOfTheWeekStateToday) {
        self.dayOfTheWeekLabel.textColor = [UIColor mit_tintColor];
    }
}

@end
