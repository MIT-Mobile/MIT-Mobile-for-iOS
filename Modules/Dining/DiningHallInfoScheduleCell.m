
#import "DiningHallInfoScheduleCell.h"
#import "UIKit+MITAdditions.h"

static CGFloat const kTopBottomOffset = 10.0;
static CGFloat const kLeftOffset = 15.0;

static CGFloat const kDaySpanLabelWidth = 66.0;
static CGFloat const kDaySpanLabelHeight = 20.0;
static CGRect const kDaySpanLabelBaseRect = {{kLeftOffset, 0}, {kDaySpanLabelWidth, kDaySpanLabelHeight}};

static CGFloat const kScheduleLabelsWidth = 100.0;

static CGFloat const kTitleDetailPadding = 6;

@interface DiningHallInfoScheduleCell ()

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) UILabel *daySpanLabel;
@property (nonatomic, strong) UILabel *scheduleLabelMealNames;
@property (nonatomic, strong) UILabel *scheduleLabelMealTimes;

@property (nonatomic, strong) NSString *mealsColumn;
@property (nonatomic, strong) NSString *timesColumn;

@property (strong, nonatomic) CALayer *cellSeparator;

@end

@implementation DiningHallInfoScheduleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.daySpanLabel = [[UILabel alloc] initWithFrame:kDaySpanLabelBaseRect];
        self.daySpanLabel.backgroundColor  = [UIColor clearColor];
        self.daySpanLabel.numberOfLines    = 1;
        self.daySpanLabel.font             = [self.class titleFont];
        self.daySpanLabel.textAlignment    = NSTextAlignmentLeft;
        self.daySpanLabel.textColor = [UIColor mit_tintColor];
        self.daySpanLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.contentView addSubview:self.daySpanLabel];
        
        CGRect scheduleLabelsFrame = CGRectMake(kLeftOffset, 0, kScheduleLabelsWidth, 0);
        self.scheduleLabelMealNames = [[UILabel alloc] initWithFrame:scheduleLabelsFrame];
        self.scheduleLabelMealNames.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelMealNames.numberOfLines       = 0;
        self.scheduleLabelMealNames.font                = [[self class] detailFont];
        self.scheduleLabelMealNames.textAlignment       = NSTextAlignmentRight;
        [self.contentView addSubview:self.scheduleLabelMealNames];
        
        self.scheduleLabelMealTimes = [[UILabel alloc] initWithFrame:scheduleLabelsFrame];
        self.scheduleLabelMealTimes.backgroundColor     = [UIColor clearColor];
        self.scheduleLabelMealTimes.numberOfLines       = 0;
        self.scheduleLabelMealTimes.font                = [[self class] detailFont];
        self.scheduleLabelMealTimes.textAlignment       = NSTextAlignmentLeft;
        [self.contentView addSubview:self.scheduleLabelMealTimes];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect daySpanFrame = kDaySpanLabelBaseRect;
    if (self.shouldIncludeTopPadding) {
        daySpanFrame.origin.y += kTopBottomOffset;
    }
    self.daySpanLabel.frame = daySpanFrame;
    
    UIFont *detailFont = [[self class] detailFont];
    
    CGFloat targetScheduleLabelHeight = self.scheduleInfo.count * detailFont.lineHeight;
    CGFloat targetOriginY = CGRectGetMaxY(self.daySpanLabel.frame) + kTitleDetailPadding;
    
    CGRect mealNamesFrame = self.scheduleLabelMealNames.frame;
    mealNamesFrame.size.height = targetScheduleLabelHeight;
    mealNamesFrame.origin.y = targetOriginY;
    self.scheduleLabelMealNames.frame = mealNamesFrame;
    
    CGRect mealTimesFrame = self.scheduleLabelMealTimes.frame;
    mealTimesFrame.size.height = targetScheduleLabelHeight;
    mealTimesFrame.origin.y = targetOriginY;
    mealTimesFrame.origin.x = CGRectGetMaxX(mealNamesFrame) + kLeftOffset;
    self.scheduleLabelMealTimes.frame = mealTimesFrame;
}

- (void)setScheduleInfo:(NSArray *)scheduleInfo
{
    _scheduleInfo = scheduleInfo;
    [self updateScheduleStrings];
}

- (void)updateScheduleStrings
{
    NSArray *meals = [self.scheduleInfo valueForKey:@"mealName"];
    self.mealsColumn = [meals componentsJoinedByString:@"\n"];
    
    NSArray *times = [self.scheduleInfo valueForKey:@"mealSpan"];
    self.timesColumn = [times componentsJoinedByString:@"\n"];

    self.scheduleLabelMealNames.text = self.mealsColumn;
    self.scheduleLabelMealTimes.text = self.timesColumn;
}

#pragma mark - Format Date Spans

- (void)setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
    self.startDate = startDate;
    self.endDate = endDate;
    
    self.daySpanLabel.text = [self formatStringforDaySpan];
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

+ (CGFloat)heightForCellWithScheduleInfo:(NSArray *)scheduleInfo withTopPadding:(BOOL)includeTopBuffer
{
    CGFloat height = 0;
    if ([scheduleInfo count]) {
        CGFloat topOffset = includeTopBuffer ? kTopBottomOffset : 0;
        height = topOffset + CGRectGetHeight(kDaySpanLabelBaseRect) + kTitleDetailPadding + ([self detailFont].lineHeight * [scheduleInfo count]) + kTopBottomOffset;
    }
    return height > 44 ? height : 44;
}

+ (UIFont *)titleFont {
    return [UIFont systemFontOfSize:15.0];
}

+ (UIFont *)detailFont {
    return [UIFont systemFontOfSize:17.0];
}

@end
