#import "MITCalendarEventCell.h"
#import "MITCalendarsLocation.h"
#import "UIKit+MITAdditions.h"

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
    self.eventTimeLabel.textColor = [UIColor mit_greyTextColor];
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

- (void)setEvent:(MITCalendarsEvent *)event withNumberPrefix:(NSString *)numberPrefix
{
    NSString *nameLabelText = event.title;
    if (numberPrefix) {
        nameLabelText = [NSString stringWithFormat:@"%@. %@", numberPrefix, nameLabelText];
    }
    self.eventNameLabel.text = nameLabelText;
    self.eventLocationLabel.text = event.location.roomNumber;
    
    self.eventTimeLabel.text = [event dateStringWithDateStyle:NSDateFormatterNoStyle
                                                timeStyle:NSDateFormatterShortStyle
                                                separator:@" "];
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
         withNumberPrefix:(NSString *)numberPrefix
           tableViewWidth:(CGFloat)width
{
    [[MITCalendarEventCell sizingCell] setEvent:event withNumberPrefix:numberPrefix];
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

#pragma mark - Selection

// Manually controlling selected appearance because if you use highlight, on scroll, cells deselect.
- (void)updateForSelected:(BOOL)selected
{
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:200/255.0 green:199/255.0 blue:204/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

@end
