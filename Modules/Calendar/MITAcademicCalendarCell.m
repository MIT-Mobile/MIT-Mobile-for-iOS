#import "MITAcademicCalendarCell.h"
#import "MITCalendarsEvent.h"

static CGFloat kMITAcademicCalendarEventCellEstimatedHeight = 44.0;

@interface MITAcademicCalendarCell ()

@property (weak, nonatomic) IBOutlet UILabel *eventDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation MITAcademicCalendarCell


- (void)setEvent:(MITCalendarsEvent *)event
{
    self.eventDescription.text = event.title;
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
           tableViewWidth:(CGFloat)width
{
    [[MITAcademicCalendarCell sizingCell] setEvent:event];
    return [MITAcademicCalendarCell heightForCell:[MITAcademicCalendarCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITAcademicCalendarCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGSize labelSize = [cell.eventDescription sizeThatFits:CGSizeMake(CGRectGetWidth(cell.eventDescription.bounds), CGFLOAT_MAX)];
    CGFloat cellSeparatorHeight = 1.0;
    CGFloat height = labelSize.height + cell.topConstraint.constant + cell.bottomConstraint.constant + cellSeparatorHeight;
    return MAX(kMITAcademicCalendarEventCellEstimatedHeight, height);
}

+ (MITAcademicCalendarCell *)sizingCell
{
    static MITAcademicCalendarCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITAcademicCalendarCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
