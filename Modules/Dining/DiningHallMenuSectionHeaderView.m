#import "DiningHallMenuSectionHeaderView.h"
#import "UIImage+PDF.h"
#import "Foundation+MITAdditions.h"
#import "DiningMeal.h"

@interface DiningHallMenuSectionHeaderView ()

@property (nonatomic, strong) UILabel       * mainLabel;
@property (nonatomic, strong) UILabel       * mealLabel;
@property (nonatomic, strong) UILabel       * timeLabel;

@property (nonatomic, strong) UIView * datePickerView;
@property (nonatomic, strong) UIView * filterView;
@property (nonatomic, strong) UIView * mealTimeView;

@property (nonatomic, strong) UIButton * leftButton;
@property (nonatomic, strong) UIButton * rightButton;

@end

@implementation DiningHallMenuSectionHeaderView

- (NSArray *) filterImages
{
    return @[@{@"icon": @"farm_to_fork.pdf",    @"title" : @"Farm to Fork"},
             @{@"icon": @"well_being.pdf",      @"title" : @"For Your Well-Being"},
             @{@"icon": @"gluten_free.pdf",     @"title" : @"Gluten Free"},
             @{@"icon": @"halal.pdf",           @"title" : @"Halal"},
             @{@"icon": @"humane.pdf",          @"title" : @"Humane"},
             @{@"icon": @"in_balance.pdf",      @"title" : @"In Balance"},
             @{@"icon": @"kosher.pdf",          @"title" : @"Kosher"},
             @{@"icon": @"organic.pdf",         @"title" : @"Organic"},
             @{@"icon": @"seafood_watch.pdf",   @"title" : @"Seafood Watch"},
             @{@"icon": @"vegan.pdf",           @"title" : @"Vegan"},
             @{@"icon": @"vegetarian.pdf",      @"title" : @"Vegetarian"}];
}


- (void) setShowMealBar:(BOOL)showMealBar
{
    _showMealBar = showMealBar;
    if (showMealBar) {
        self.mealTimeView.hidden = NO;
    } else {
        self.mealTimeView.hidden = YES;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.datePickerView = [self viewForDateAndArrows];
        self.mealTimeView = [self viewForMealTime];
        
        [self addSubview:self.datePickerView];
        [self addSubview:self.mealTimeView];
        
    }
    return self;
}

- (void) setCurrentFilters:(NSArray *)currentFilters
{
    _currentFilters = currentFilters;
    [self.filterView removeFromSuperview];
    if ([self.currentFilters count]) {
        self.filterView = [self viewForEnabledFilters];
        [self addSubview:self.filterView];
    }
}



- (UIView *) viewForDateAndArrows
{
    CGFloat rowHeight = 30;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), rowHeight)];
    view.backgroundColor = [UIColor darkGrayColor];
    
    UIImage *arrow = [UIImage imageNamed:@"global/action-arrow-white.png"];
    
    self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftButton.imageView.transform = CGAffineTransformMakeRotation(M_PI); // flip the image view
    [self.leftButton setImage:arrow forState:UIControlStateNormal];
    self.leftButton.frame = CGRectMake(0, 0, 40, 50);
    self.leftButton.center = CGPointMake(20, rowHeight * 0.5);
    
    
    self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightButton setImage:arrow forState:UIControlStateNormal];
    self.rightButton.frame = CGRectMake(0, 0, 40, 50);
    self.rightButton.center = CGPointMake(CGRectGetWidth(view.bounds) - 20, rowHeight * 0.5);
    
    CGFloat hPadding = 28.0;
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPadding, 9, CGRectGetWidth(view.bounds) - (2 * hPadding), 12)];
    self.mainLabel.text = @"Today's Dinner, March 1";
    self.mainLabel.textAlignment = NSTextAlignmentCenter;
    self.mainLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    self.mainLabel.textColor = [UIColor whiteColor];
    self.mainLabel.backgroundColor = [UIColor clearColor];
    
    [view addSubview:self.mainLabel];
    [view addSubview:self.leftButton];
    [view addSubview:self.rightButton];
    
    return view;
}

- (UIView *) viewForEnabledFilters
{
    CGFloat rowHeight = [[self class] heightForFilterBar];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), rowHeight)];
    view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 9, 35, 12)]; // width is arbitrary, height matches font size
    label.text = @"Filters";
    label.font = [UIFont fontWithName:@"Helvetica" size:12];
    label.textColor = [UIColor darkTextColor];
    label.backgroundColor = [UIColor clearColor];
    
    [view addSubview:label];
    
    CGSize iconSize = CGSizeMake(16, 16);
    CGFloat offset = CGRectGetMaxX(label.frame) + 10 + 8;   //  
    for (int i = 0; i < [self.currentFilters count]; i++) {
        NSString *iconPath = [NSString stringWithFormat:@"dining/%@.pdf", self.currentFilters[i]];
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageWithPDFNamed:iconPath atSize:iconSize]];
        icon.center = CGPointMake(offset + (23 * i), 15);
        [view addSubview:icon];
    }
    
    return view;
}

- (UIView *) viewForMealTime
{
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), [[self class] heightForMealBar])];
    view.backgroundColor = [UIColor darkTextColor];
    
    self.mealLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, CGRectGetWidth(view.bounds) - 20, 12)]; // 7px vertical padding, width is arbitrary, height matches font size
    self.mealLabel.textAlignment = NSTextAlignmentLeft;
    self.mealLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    self.mealLabel.textColor = [UIColor whiteColor];
    self.mealLabel.backgroundColor = [UIColor clearColor];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, CGRectGetWidth(view.bounds) - 20, 12)]; // 7px vertical padding, width is arbitrary, height matches font size
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    self.timeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.backgroundColor = [UIColor clearColor];
    
    [view addSubview:self.mealLabel];
    [view addSubview:self.timeLabel];
    
    return view;
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // need to re-align stack of views
    //      datePickerview
    //      filterView
    //      meal/time view

    CGRect frame = self.datePickerView.frame;
    frame.origin = CGPointMake(0, 0);
    self.datePickerView.frame = frame;
    
    
    frame = self.filterView.frame;
    frame.origin = CGPointMake(0, CGRectGetMaxY(self.datePickerView.frame));
    self.filterView.frame=frame;
    
    frame = self.mealTimeView.frame;
    frame.origin = ([self.currentFilters count]) ? CGPointMake(0, CGRectGetMaxY(self.filterView.frame)) : CGPointMake(0, CGRectGetMaxY(self.datePickerView.frame)); //if there are no filters have only two bars
    self.mealTimeView.frame = frame;
    
}


+ (NSString *) stringForMeal:(DiningMeal *) meal
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *date = meal.startTime;
    
    NSString *dayString;
    if ([date isToday]) {
        dayString = @"Today";
    } else if ([date isTomorrow]) {
        dayString = @"Tomorrow";
    } else if ([date isYesterday]) {
        dayString = @"Yesterday";
    } else {
        [dateFormatter setDateFormat:@"EEEE"];
        dayString = [dateFormatter stringFromDate:date];
    }
    
    [dateFormatter setDateFormat:@"MMM d"];
    NSString *fullDate = [dateFormatter stringFromDate:date];
    
    if (meal) {
        NSString * mealString = [meal.name capitalizedString];
        return [NSString stringWithFormat:@"%@'s %@, %@", dayString, mealString, fullDate];
    } else {
        return [NSString stringWithFormat:@"%@, %@", dayString, fullDate];
    }
    
}

+ (CGFloat) heightForPagerBar
{
    return 30;
}

+ (CGFloat) heightForFilterBar
{
    return 30;
}

+ (CGFloat) heightForMealBar
{
    return 26;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
