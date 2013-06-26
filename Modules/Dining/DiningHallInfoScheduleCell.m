
#import "DiningHallInfoScheduleCell.h"


@interface DiningHallInfoScheduleCell ()

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) UILabel * spanLabel;
@property (nonatomic, strong) UILabel * scheduleLabelMeals;
@property (nonatomic, strong) UILabel * scheduleLabelTimes;

@property (nonatomic, strong) NSString * mealsColumn;
@property (nonatomic, strong) NSString * timesColumn;

@end

@implementation DiningHallInfoScheduleCell

static const NSInteger lineHeight = 16;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.spanLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 66, 12)];        // height set for single line of text
        self.spanLabel.backgroundColor  = [UIColor clearColor];
        self.spanLabel.numberOfLines    = 1;
        self.spanLabel.font             = [UIFont boldSystemFontOfSize:13];
        self.spanLabel.textAlignment    = NSTextAlignmentRight;
        [self.contentView addSubview:self.spanLabel];
        
        
        CGRect frame = CGRectMake(83, 9, 205, lineHeight);
        self.scheduleLabelMeals = [[UILabel alloc] initWithFrame:frame];
        self.scheduleLabelMeals.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelMeals.numberOfLines       = 0;
        self.scheduleLabelMeals.font                = [UIFont systemFontOfSize:14];
        self.scheduleLabelMeals.textAlignment       = NSTextAlignmentLeft;
        [self.contentView addSubview:self.scheduleLabelMeals];
        
        self.scheduleLabelTimes = [[UILabel alloc] initWithFrame:frame];
        self.scheduleLabelTimes.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelTimes.numberOfLines       = 0;
        self.scheduleLabelTimes.font                = [UIFont systemFontOfSize:14];
        self.scheduleLabelTimes.textAlignment       = NSTextAlignmentRight;
        [self.contentView addSubview:self.scheduleLabelTimes];
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = [self.scheduleInfo count] * lineHeight;
    CGRect frame = self.scheduleLabelTimes.frame;
    frame.size.height = height;
    self.scheduleLabelTimes.frame = frame;
    self.scheduleLabelMeals.frame = frame;
}

- (void) setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
    self.startDate = startDate;
    self.endDate = endDate;
    
    self.spanLabel.text = [self formatStringforDaySpan];
}

- (void) setScheduleInfo:(NSArray *)scheduleInfo
{
    _scheduleInfo = scheduleInfo;
    [self updateScheduleStrings];
}

- (void) updateScheduleStrings
{
    NSLog(@"%@", self.scheduleInfo);
    NSArray *meals = [self.scheduleInfo valueForKey:@"mealName"];
    self.mealsColumn = [meals componentsJoinedByString:@"\n"];
    
    NSArray *times = [self.scheduleInfo valueForKey:@"mealSpan"];
    self.timesColumn = [times componentsJoinedByString:@"\n"];

    self.scheduleLabelMeals.text = self.mealsColumn;
    self.scheduleLabelTimes.text = self.timesColumn;
}

- (NSString *) formatStringforDaySpan
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

+ (CGFloat) heightForCellWithScheduleInfo:(NSArray *)scheduleInfo
{
    if ([scheduleInfo count]) {
        return 20 + (lineHeight * [scheduleInfo count]);        // vertical padding plus size of schedule text
    }
    return 44;
}

@end
