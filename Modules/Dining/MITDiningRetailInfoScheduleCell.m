#import "MITDiningRetailInfoScheduleCell.h"

@interface MITDiningRetailInfoScheduleCell ()

@property (strong, nonatomic) NSDateFormatter *daySpanFormatter;

@end

@implementation MITDiningRetailInfoScheduleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel.text = @"hours";
        self.shouldIncludeTopPadding = YES;
    }
    return self;
}

+ (CGFloat)heightForCellWithScheduleInfo:(NSArray *)scheduleInfo
{
    CGFloat height = 0;
    if ([scheduleInfo count]) {
        height = [self heightForCellWithNumberOfRowsInEachColumn:scheduleInfo.count withTopPadding:YES];
    }
    return height > 44 ? height : 44;
}

#pragma mark - Getters | Setters

- (void)setScheduleInfo:(NSArray *)scheduleInfo
{
    _scheduleInfo = scheduleInfo;
    self.numberOfRowsInEachColumn = scheduleInfo.count;
    NSMutableArray *leftColumnStrings = [NSMutableArray array];
    NSMutableArray *rightColumnStrings = [NSMutableArray array];
    for (NSDictionary *schedule in scheduleInfo) {
        NSDate *startDate = schedule[@"dayStart"];
        NSDate *endDate = schedule[@"dayEnd"];
        NSString *daySpanString = nil;
        NSString *startDayString = [[self.daySpanFormatter stringFromDate:startDate] capitalizedString];
        if (![startDate isEqualToDate:endDate]) {
            NSString *endDayString = [[self.daySpanFormatter stringFromDate:endDate] capitalizedString];
            daySpanString = [NSString stringWithFormat:@"%@ - %@", startDayString, endDayString];
        } else {
            daySpanString = startDayString;
        }
        [leftColumnStrings addObject:daySpanString];
        [rightColumnStrings addObject:schedule[@"hours"]];
    }
    
    self.leftColumnLabel.text = [leftColumnStrings componentsJoinedByString:@"\n"];
    self.rightColumnLabel.text = [rightColumnStrings componentsJoinedByString:@"\n"];
}

- (NSDateFormatter *)daySpanFormatter
{
    if (!_daySpanFormatter) {
        _daySpanFormatter = [[NSDateFormatter alloc] init];
        [_daySpanFormatter setDateFormat:@"EEE"];
    }
    return _daySpanFormatter;
}

@end
