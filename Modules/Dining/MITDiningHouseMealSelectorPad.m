#import "MITDiningHouseMealSelectorPad.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "MITDiningHouseVenue.h"
#import "Foundation+MITAdditions.h"
#import "MITAdditions.h"

@interface MITDiningHouseMealSelectorPad ()

@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSDictionary *dateKeyedMeals;
@property (nonatomic, strong) NSDictionary *mealsByLetterView;
@property (nonatomic, strong) NSDictionary *letterViewsByDate;
@property (nonatomic, strong) NSDictionary *dateLabelsByDate;
@property (nonatomic, strong) UILabel *selectedMealNameLabel;
@property (nonatomic, strong) UIView *selectedMealBackground;
@property (nonatomic, weak) UILabel *currentlySelectedLetterView;

@end

@implementation MITDiningHouseMealSelectorPad

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self repositionViews];
}

- (UIView *)selectedMealBackground
{
    if (!_selectedMealBackground) {
        _selectedMealBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        _selectedMealBackground.backgroundColor = [UIColor mit_tintColor];
        _selectedMealBackground.layer.cornerRadius = 12;
        _selectedMealBackground.hidden = YES;
        [self addSubview:_selectedMealBackground];
    }
    
    return _selectedMealBackground;
}

- (UILabel *)selectedMealNameLabel
{
    if (!_selectedMealNameLabel) {
        _selectedMealNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 16)];
        _selectedMealNameLabel.font = [UIFont systemFontOfSize:12];
        _selectedMealNameLabel.textAlignment = NSTextAlignmentCenter;
        _selectedMealNameLabel.textColor = [UIColor mit_tintColor];
        _selectedMealNameLabel.hidden = YES;
        [self addSubview:_selectedMealNameLabel];
    }
    
    return _selectedMealNameLabel;
}

#pragma mark - Public Methods

- (void)setVenues:(NSArray *)venues
{
    if ([venues isEqual:_venues]) {
        return;
    }
    
    _venues = [NSArray arrayWithArray:venues];
    
    [self refreshDateKeyedMeals];
    [self refreshViews];
}

- (void)selectMeal:(NSString *)meal onDate:(NSDate *)date
{
    [self mealSelected:meal onDate:date];
}

#pragma mark - Private Methods

- (void)selectLetterView:(UILabel *)letterView
{
    letterView.textColor = [UIColor whiteColor];
    self.selectedMealBackground.center = letterView.center;
    self.selectedMealBackground.hidden = NO;
    [self bringSubviewToFront:letterView];
    
    CGPoint selectedMealNameLabelCenter = self.selectedMealNameLabel.center;
    selectedMealNameLabelCenter.x = letterView.center.x;
    self.selectedMealNameLabel.center = selectedMealNameLabelCenter;
    
    self.selectedMealNameLabel.hidden = NO;
    
    self.currentlySelectedLetterView = letterView;
}

- (void)deselectLetterView:(UILabel *)letterView
{
    letterView.textColor = [UIColor blackColor];
    self.selectedMealBackground.hidden = YES;
    self.selectedMealNameLabel.hidden = YES;
    self.currentlySelectedLetterView = nil;
}

- (void)mealSelected:(NSString *)mealName onDate:(NSDate *)date
{
    [self deselectLetterView:self.currentlySelectedLetterView];
    
    for (NSDate *dateKey in [self.letterViewsByDate allKeys]) {
        if ([[dateKey dateWithoutTime] isEqualToDate:[date dateWithoutTime]]) {
            NSOrderedSet *letterViews = [self.letterViewsByDate objectForKey:dateKey];
            for (UILabel *letterView in letterViews) {
                MITDiningMeal *meal = [self.mealsByLetterView objectForKey:[NSString stringWithFormat:@"%p", letterView]];
                if ([meal.name isEqualToString:mealName]) {
                    self.selectedMealNameLabel.text = [meal titleCaseName];
                    [self selectLetterView:letterView];
                    break;
                }
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(diningHouseMealSelector:didSelectMeal:onDate:)]) {
        [self.delegate diningHouseMealSelector:self didSelectMeal:mealName onDate:date];
    }
}

- (void)refreshDateKeyedMeals
{
    NSMutableDictionary *newDateKeyedMeals = [NSMutableDictionary dictionary];
    
    for (MITDiningHouseVenue *venue in self.venues) {
        for (MITDiningHouseDay *day in venue.mealsByDay) {
            NSMutableOrderedSet *currentMealsForDate = [newDateKeyedMeals objectForKey:day.date];
            
            if (!currentMealsForDate) {
                currentMealsForDate = [NSMutableOrderedSet orderedSet];
            }

            for (MITDiningMeal *meal in day.meals) {
                NSUInteger indexOfMatchingString = [currentMealsForDate indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    MITDiningMeal *mealInSet = obj;
                    return [meal.name isEqualToString:mealInSet.name];
                }];
                if (indexOfMatchingString == NSNotFound) {
                    [currentMealsForDate addObject:meal];
                }
            }
            
            [newDateKeyedMeals setObject:currentMealsForDate forKey:day.date];
        }
    }
    
    NSArray *allKeys = [newDateKeyedMeals allKeys];
    for (id key in allKeys) {
        NSOrderedSet *dateSortedMeals = [newDateKeyedMeals objectForKey:key];
        dateSortedMeals = [NSOrderedSet orderedSetWithArray:[dateSortedMeals sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            MITDiningMeal *meal1 = obj1;
            MITDiningMeal *meal2 = obj2;
            return [meal1.startTime compare:meal2.startTime];
        }]];
        [newDateKeyedMeals setObject:dateSortedMeals forKey:key];
    }
    
    self.dateKeyedMeals = [NSDictionary dictionaryWithDictionary:newDateKeyedMeals];
}

- (void)refreshViews
{
    for (NSDate *dateKey in [self.letterViewsByDate allKeys]) {
        UILabel *dateLabel = [self.dateLabelsByDate objectForKey:dateKey];
        [dateLabel removeFromSuperview];
        NSOrderedSet *letterViews = [self.letterViewsByDate objectForKey:dateKey];
        for (UILabel *letterView in letterViews) {
            [letterView removeFromSuperview];
        }
    }
    
    NSArray *dateOrderedKeys = [[self.dateKeyedMeals allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableDictionary *newMealsByLetterView = [NSMutableDictionary dictionary];
    NSMutableDictionary *newLetterViewsByDate = [NSMutableDictionary dictionary];
    NSMutableDictionary *newDateLabelsByDate = [NSMutableDictionary dictionary];
    
    for (NSInteger i = 0; i < dateOrderedKeys.count; i++) {
        NSDate *date = dateOrderedKeys[i];
        NSOrderedSet *meals = [self.dateKeyedMeals objectForKey:date];
        
        NSMutableOrderedSet *letterViewsForCurrentDate = [NSMutableOrderedSet orderedSet];
        
        for (NSInteger j = 0; j < meals.count; j++) {
            MITDiningMeal *meal = meals[j];
            
            UILabel *mealLetterLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            mealLetterLabel.text = [[meal.name substringToIndex:1] uppercaseString];
            mealLetterLabel.userInteractionEnabled = YES;
            mealLetterLabel.textAlignment = NSTextAlignmentCenter;
            mealLetterLabel.backgroundColor = [UIColor clearColor];
            [mealLetterLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(letterViewTapped:)]];
            [self addSubview:mealLetterLabel];
            
            [newMealsByLetterView setObject:meal forKey:[NSString stringWithFormat:@"%p", mealLetterLabel]];
            [letterViewsForCurrentDate addObject:mealLetterLabel];
        }
        
        [newLetterViewsByDate setObject:letterViewsForCurrentDate forKey:date];
        
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        dateLabel.text = [self stringForMealDate:date];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.font = [UIFont systemFontOfSize:12];
        
        
        [self addSubview:dateLabel];
        [newDateLabelsByDate setObject:dateLabel forKey:date];
    }
    
    self.mealsByLetterView = [NSDictionary dictionaryWithDictionary:newMealsByLetterView];
    self.letterViewsByDate = [NSDictionary dictionaryWithDictionary:newLetterViewsByDate];
    self.dateLabelsByDate = [NSDictionary dictionaryWithDictionary:newDateLabelsByDate];
    
    [self repositionViews];
}

- (void)repositionViews
{
    
    NSArray *dateOrderedKeys = [[self.dateKeyedMeals allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSInteger totalMeals = 0;
    for (id key in dateOrderedKeys) {
        NSOrderedSet *mealsAtDate = [self.dateKeyedMeals objectForKey:key];
        totalMeals += mealsAtDate.count;
    }
    
    CGFloat mealLetterLabelSize = 20; // 18pt square for each letter
    CGFloat selectedMealNameLabelHeight = self.selectedMealNameLabel.bounds.size.height;
    CGFloat dateLabelHeight = selectedMealNameLabelHeight;
    CGFloat verticalPadding = 10;
    
    CGFloat totalViewSpace = self.bounds.size.width - (2 * self.horizontalInset) - mealLetterLabelSize;
    CGFloat totalSpacingSpace = totalViewSpace - (totalMeals * mealLetterLabelSize);
    
    CGFloat numberOfInterDaySpaces = dateOrderedKeys.count - 1;
    CGFloat interDaySpacingWeight = 2.0;
    CGFloat weightedInterDaySpaces = numberOfInterDaySpaces * interDaySpacingWeight;
    
    CGFloat numberOfInterMealSpaces = totalMeals - 1 - numberOfInterDaySpaces;
    CGFloat interMealSpacingWeight = 1.0;
    CGFloat weightedInterMealSpaces = numberOfInterMealSpaces * interMealSpacingWeight;
    
    CGFloat totalInterDaySpace = (weightedInterDaySpaces / (weightedInterDaySpaces + weightedInterMealSpaces)) * totalSpacingSpace;
    CGFloat totalInterMealSpace = totalSpacingSpace - totalInterDaySpace;
    
    CGFloat interDaySpacing = totalInterDaySpace / numberOfInterDaySpaces;
    CGFloat interMealSpacing = totalInterMealSpace / numberOfInterMealSpaces;
    
    CGFloat currentXOffset = self.horizontalInset;
    
    for (NSInteger i = 0; i < dateOrderedKeys.count; i++) {
        NSDate *date = dateOrderedKeys[i];
        NSOrderedSet *letterViews = [self.letterViewsByDate objectForKey:date];
        
        CGFloat sectionXOffset = currentXOffset;
        
        for (NSInteger j = 0; j < letterViews.count; j++) {
            UILabel *letterView = letterViews[j];
            letterView.frame = CGRectMake(currentXOffset, self.bounds.size.height - selectedMealNameLabelHeight - mealLetterLabelSize - verticalPadding, mealLetterLabelSize, mealLetterLabelSize);
            
            currentXOffset += mealLetterLabelSize;
            if (j != letterViews.count - 1) {
                currentXOffset += interMealSpacing;
            }
        }
        
        UILabel *dateLabel = [self.dateLabelsByDate objectForKey:date];
        dateLabel.frame = CGRectMake(sectionXOffset, self.bounds.size.height - selectedMealNameLabelHeight - mealLetterLabelSize - (2 * verticalPadding) - dateLabelHeight, currentXOffset - sectionXOffset, 14);
        
        CGFloat dateLabelCenterX = dateLabel.center.x;
        
        CGRect dateLabelFrame = dateLabel.frame;
        dateLabelFrame.size.width = [dateLabel sizeThatFits:dateLabelFrame.size].width;
        dateLabel.frame = dateLabelFrame;
        
        CGPoint dateLabelCenter = dateLabel.center;
        dateLabelCenter.x = dateLabelCenterX;
        dateLabel.center = dateLabelCenter;
        
        currentXOffset += interDaySpacing;
    }
    
    if (self.currentlySelectedLetterView) {
        self.selectedMealBackground.center = self.currentlySelectedLetterView.center;
        [self bringSubviewToFront:self.currentlySelectedLetterView];
        
        self.selectedMealNameLabel.frame = CGRectMake(0, self.bounds.size.height - selectedMealNameLabelHeight - verticalPadding, self.selectedMealNameLabel.frame.size.width, self.selectedMealNameLabel.frame.size.height);
        CGPoint selectedMealNameLabelCenter = self.selectedMealNameLabel.center;
        selectedMealNameLabelCenter.x = self.currentlySelectedLetterView.center.x;
        self.selectedMealNameLabel.center = selectedMealNameLabelCenter;
    }
}

- (void)letterViewTapped:(id)sender
{
    UITapGestureRecognizer *recognizer = sender;
    MITDiningMeal *meal = [self.mealsByLetterView objectForKey:[NSString stringWithFormat:@"%p", recognizer.view]];
    [self mealSelected:meal.name onDate:[self dateForMeal:meal]];
}

- (NSDate *)dateForMeal:(MITDiningMeal *)meal
{
    for (NSDate *dateKey in [self.dateKeyedMeals allKeys]) {
        NSOrderedSet *meals = [self.dateKeyedMeals objectForKey:dateKey];
        for (MITDiningMeal *mealInSet in meals) {
            if ([mealInSet isEqual:meal]) {
                return dateKey;
            }
        }
    }
    
    return nil;
}

- (NSString *)stringForMealDate:(NSDate *)date
{
    static NSDateFormatter *mealDateFormatter;
    if (!mealDateFormatter) {
        mealDateFormatter = [[NSDateFormatter alloc] init];
        [mealDateFormatter setDateFormat:@"E d"];
    }
    
    NSDate *currentDateWithoutTime = [[NSDate date] dateWithoutTime];
    NSDateComponents *inputDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:date];
    
    if ([[date dateWithoutTime] isEqualToDate:currentDateWithoutTime]) {
        return [NSString stringWithFormat:@"Today %li", (long)inputDateComps.day];
    } else if ([[date dateWithoutTime] timeIntervalSince1970] == ([currentDateWithoutTime timeIntervalSince1970] - 60 * 60 * 24)) {
        return [NSString stringWithFormat:@"Yesterday %li", (long)inputDateComps.day];
    } else if ([[date dateWithoutTime] timeIntervalSince1970] == ([currentDateWithoutTime timeIntervalSince1970] + 60 * 60 * 24)) {
        return [NSString stringWithFormat:@"Tomorrow %li", (long)inputDateComps.day];
    } else {
        return [mealDateFormatter stringFromDate:date];
    }
}

@end
