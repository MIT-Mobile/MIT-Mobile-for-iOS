#import "MITAcademicCalendarCell.h"
#import "MITCalendarsEvent.h"

static CGFloat kMITAcademicCalendarEventCellEstimatedHeight = 44.0;

@interface MITAcademicCalendarCell ()

@property (weak, nonatomic) IBOutlet UILabel *eventDescription;

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
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
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
