
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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.spanLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 66, 0)];
        self.spanLabel.backgroundColor  = [UIColor clearColor];
        self.spanLabel.numberOfLines    = 1;
        self.spanLabel.font             = [[self class] labelFont];
        self.spanLabel.textAlignment    = NSTextAlignmentRight;
        [self.contentView addSubview:self.spanLabel];
        
        CGRect frame = CGRectMake(83, 0, 205, 0);
        self.scheduleLabelMeals = [[UILabel alloc] initWithFrame:frame];
        self.scheduleLabelMeals.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelMeals.numberOfLines       = 0;
        self.scheduleLabelMeals.font                = [[self class] detailFont];
        self.scheduleLabelMeals.textAlignment       = NSTextAlignmentLeft;
        [self.contentView addSubview:self.scheduleLabelMeals];
        
        self.scheduleLabelTimes = [[UILabel alloc] initWithFrame:frame];
        self.scheduleLabelTimes.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelTimes.numberOfLines       = 0;
        self.scheduleLabelTimes.font                = [[self class] detailFont];
        self.scheduleLabelTimes.textAlignment       = NSTextAlignmentRight;
        [self.contentView addSubview:self.scheduleLabelTimes];
    }
    return self;
}

+ (UIFont *)labelFont {
    return [UIFont boldSystemFontOfSize:12];
}

+ (UIFont *)detailFont {
    return [UIFont systemFontOfSize:13];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    UIFont *labelFont = [[self class] labelFont];
    UIFont *detailFont = [[self class] detailFont];
    
    CGRect frame = self.scheduleLabelTimes.frame;
    frame.size.height = [self.scheduleInfo count] * [[self class] detailFont].lineHeight;
    CGFloat topPadding = round((CGRectGetHeight(self.bounds) - CGRectGetHeight(frame)) * 0.5) - 1;
    frame.origin.y = topPadding;

    self.scheduleLabelTimes.frame = frame;
    self.scheduleLabelMeals.frame = frame;
    
    // Match the baselines between the UILabels despite their differing font sizes. Account for rounding differences on Retina displays.
    CGRect spanFrame = self.spanLabel.frame;
    const CGFloat scale = [UIScreen mainScreen].scale;
    spanFrame.origin.y = topPadding + ceil(((detailFont.lineHeight + detailFont.descender) - (labelFont.lineHeight + labelFont.descender)) * scale) / scale;
    spanFrame.size.height = labelFont.lineHeight;
    self.spanLabel.frame = spanFrame;
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
        return 20 + ([self detailFont].lineHeight * [scheduleInfo count]);        // vertical padding plus size of schedule text
    }
    return 44;
}

@end
