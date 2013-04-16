//
//  DiningHallMenuSectionHeaderView.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/12/13.
//
//

#import "DiningHallMenuSectionHeaderView.h"
#import "UIImage+PDF.h"

@interface DiningHallMenuSectionHeaderView ()

@property (nonatomic, strong) UIView * datePickerView;
@property (nonatomic, strong) UIView * filterView;
@property (nonatomic, strong) UIView * dateTimeView;

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

- (NSDictionary *) debugMeal
{
    return @{@"title": @"Dinner", @"time":@"5:30pm - 8:30pm"};
}

- (NSArray *) debugEnabledFilters
{
    return @[@1,@2,@5,@7,@9];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.meal = [self debugMeal];
        
        self.datePickerView = [self viewForDateAndArrows];
        self.dateTimeView = [self viewForMealTime];
        
        [self addSubview:self.datePickerView];
        [self addSubview:self.dateTimeView];
        
    }
    return self;
}

- (void) setCurrentFilters:(NSArray *)currentFilters
{
    _currentFilters = currentFilters;
    [self.filterView removeFromSuperview];
    self.filterView = [self viewForEnabledFilters];
    [self addSubview:self.filterView];
}



- (UIView *) viewForDateAndArrows
{
    
    return nil;
}

- (UIView *) viewForEnabledFilters
{
    CGFloat rowHeight = 30;
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
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 26)];
    view.backgroundColor = [UIColor darkTextColor];
    
    UILabel *mealLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, CGRectGetWidth(view.bounds) - 20, 12)]; // 7px vertical padding, width is arbitrary, height matches font size
    mealLabel.text = [self debugMeal][@"title"];
    mealLabel.textAlignment = NSTextAlignmentLeft;
    mealLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    mealLabel.textColor = [UIColor whiteColor];
    mealLabel.backgroundColor = [UIColor clearColor];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, CGRectGetWidth(view.bounds) - 20, 12)]; // 7px vertical padding, width is arbitrary, height matches font size
    timeLabel.text = [self debugMeal][@"time"];
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    
    [view addSubview:mealLabel];
    [view addSubview:timeLabel];
    
    return view;
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // need to re-align stack of views
    //      datePickerview
    //      filterView
    //      meal view
    
//    self.datePickerView setFrame:
    CGRect frame = self.filterView.frame;
    frame.origin = CGPointMake(0, 0);
    self.filterView.frame=frame;
    
    frame = self.dateTimeView.frame;
    frame.origin = CGPointMake(0, CGRectGetMaxY(self.filterView.frame));
    self.dateTimeView.frame = frame;
    
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
