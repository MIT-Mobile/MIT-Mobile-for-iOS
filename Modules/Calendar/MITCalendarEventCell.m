#import "MITCalendarEventCell.h"
#import "MITCalendarsLocation.h"

static CGFloat kMITCalendarEventCellEstimatedHeight = 80.0;

@interface MITCalendarEventCell ()

@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *eventLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventTimeLabel;

@end

@implementation MITCalendarEventCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
    self.eventLocationLabel.textColor =
    self.eventTimeLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.eventNameLabel.preferredMaxLayoutWidth = self.eventNameLabel.frame.size.width;
    self.eventLocationLabel.preferredMaxLayoutWidth = self.eventLocationLabel.frame.size.width;
    self.eventTimeLabel.preferredMaxLayoutWidth = self.eventTimeLabel.frame.size.width;
}

#pragma mark - Event

- (void)setEvent:(MITCalendarsEvent *)event
{
    self.eventNameLabel.text = event.title;
    self.eventLocationLabel.text = event.location.roomNumber;
    
    self.eventTimeLabel.text = [event dateStringWithDateStyle:NSDateFormatterNoStyle
                                                timeStyle:NSDateFormatterShortStyle
                                                separator:@" "];
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
           tableViewWidth:(CGFloat)width
{
    [[MITCalendarEventCell sizingCell] setEvent:event];
    return [MITCalendarEventCell heightForCell:[MITCalendarEventCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITCalendarEventCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITCalendarEventCellEstimatedHeight, height);
}

+ (MITCalendarEventCell *)sizingCell
{
    static MITCalendarEventCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITCalendarEventCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}


@end
