
#import "DiningHallInfoScheduleCell.h"
#import "UIKit+MITAdditions.h"

@interface DiningHallInfoScheduleCell ()

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;

@property (nonatomic, strong) NSString *mealsColumn;
@property (nonatomic, strong) NSString *timesColumn;

@property (strong, nonatomic) CALayer *cellSeparator;

@end

@implementation DiningHallInfoScheduleCell

- (void)setScheduleInfo:(NSArray *)scheduleInfo
{
    _scheduleInfo = scheduleInfo;
    self.numberOfRowsInEachColumn = scheduleInfo.count;
    [self updateScheduleStrings];
}

- (void)updateScheduleStrings
{
    NSArray *meals = [self.scheduleInfo valueForKey:@"mealName"];
    self.mealsColumn = [meals componentsJoinedByString:@"\n"];
    
    NSArray *times = [self.scheduleInfo valueForKey:@"mealSpan"];
    self.timesColumn = [times componentsJoinedByString:@"\n"];

    self.leftColumnLabel.text = self.mealsColumn;
    self.rightColumnLabel.text = self.timesColumn;
}

#pragma mark - Format Date Spans

- (void)setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
    self.startDate = startDate;
    self.endDate = endDate;
    
    self.titleLabel.text = [self formatStringforDaySpan];
}

- (NSString *)formatStringforDaySpan
{
    if (!self.startDate) {
        return @"";
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE"];
    NSString *daySpan;
    if ([self.startDate isEqual:self.endDate]) {
        daySpan = [[df stringFromDate:self.startDate] lowercaseString];
    } else {
        daySpan = [NSString stringWithFormat:@"%@ - %@", [[df stringFromDate:self.startDate] lowercaseString], [[df stringFromDate:self.endDate] lowercaseString]];
    }
    return daySpan;
}

#pragma mark - Class Methods

+ (CGFloat)heightForCellWithScheduleInfo:(NSArray *)scheduleInfo withTopPadding:(BOOL)includeTopPadding
{
    CGFloat height = 0;
    if ([scheduleInfo count]) {
        height = [self heightForCellWithNumberOfRowsInEachColumn:scheduleInfo.count withTopPadding:includeTopPadding];
    }
    return height > 44 ? height : 44;
}


@end
