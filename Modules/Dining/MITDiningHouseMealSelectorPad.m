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
    
    [self refreshViews];
}

- (UIView *)selectedMealBackground
{
    if (!_selectedMealBackground) {
        _selectedMealBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _selectedMealBackground.backgroundColor = [UIColor redColor];
        _selectedMealBackground.hidden = YES;
        [self addSubview:_selectedMealBackground];
    }
    
    return _selectedMealBackground;
}

#pragma mark - Public Methods

- (void)setVenues:(NSArray *)venues
{
    if ([venues isEqual:_venues]) {
        return;
    }
    
    _venues = venues;
    
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
    self.currentlySelectedLetterView = letterView;
}

- (void)deselectLetterView:(UILabel *)letterView
{
    if (![self.currentlySelectedLetterView isEqual:letterView]) {
        return;
    }
    
    letterView.textColor = [UIColor blackColor];
    self.selectedMealBackground.hidden = YES;
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
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    NSArray *dateOrderedKeys = [[self.dateKeyedMeals allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSInteger totalMeals = 0;
    for (id key in dateOrderedKeys) {
        NSOrderedSet *mealsAtDate = [self.dateKeyedMeals objectForKey:key];
        totalMeals += mealsAtDate.count;
    }
    
    CGFloat mealLetterLabelSize = 20; // 18pt square for each letter
    CGFloat selectedMealNameLabelHeight = 14;
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
    
    NSMutableDictionary *newMealsByLetterView = [NSMutableDictionary dictionary];
    NSMutableDictionary *newLetterViewsByDate = [NSMutableDictionary dictionary];
    
    for (NSInteger i = 0; i < dateOrderedKeys.count; i++) {
        NSDate *date = dateOrderedKeys[i];
        NSOrderedSet *meals = [self.dateKeyedMeals objectForKey:date];
        
        NSMutableOrderedSet *letterViewsForCurrentDate = [NSMutableOrderedSet orderedSet];
        CGFloat sectionXOffset = currentXOffset;
        
        for (NSInteger j = 0; j < meals.count; j++) {
            MITDiningMeal *meal = meals[j];
            
            UILabel *mealLetterLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentXOffset, self.bounds.size.height - mealLetterLabelSize - verticalPadding, mealLetterLabelSize, mealLetterLabelSize)];
            mealLetterLabel.text = [[meal.name substringToIndex:1] uppercaseString];
            mealLetterLabel.userInteractionEnabled = YES;
            mealLetterLabel.textAlignment = NSTextAlignmentCenter;
            mealLetterLabel.backgroundColor = [UIColor clearColor];
            [mealLetterLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(letterViewTapped:)]];
            [self addSubview:mealLetterLabel];
            
            [newMealsByLetterView setObject:meal forKey:[NSString stringWithFormat:@"%p", mealLetterLabel]];
            [letterViewsForCurrentDate addObject:mealLetterLabel];
            
            currentXOffset += mealLetterLabelSize;
            if (j != meals.count - 1) {
                currentXOffset += interMealSpacing;
            }
        }
        
        [newLetterViewsByDate setObject:letterViewsForCurrentDate forKey:date];
        
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(sectionXOffset, self.bounds.size.height - mealLetterLabelSize - (2 * verticalPadding) - dateLabelHeight, currentXOffset - sectionXOffset, 14)];
        CGFloat dateLabelCenterX = dateLabel.center.x;
        dateLabel.text = [self stringForMealDate:date];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.font = [UIFont systemFontOfSize:12];
        CGRect dateLabelFrame = dateLabel.frame;
        dateLabelFrame.size.width = [dateLabel sizeThatFits:dateLabelFrame.size].width;
        dateLabel.frame = dateLabelFrame;
        
        CGPoint dateLabelCenter = dateLabel.center;
        dateLabelCenter.x = dateLabelCenterX;
        dateLabel.center = dateLabelCenter;
        
        [self addSubview:dateLabel];
        
        currentXOffset += interDaySpacing;
    }
    
    self.mealsByLetterView = [NSDictionary dictionaryWithDictionary:newMealsByLetterView];
    self.letterViewsByDate = [NSDictionary dictionaryWithDictionary:newLetterViewsByDate];
}

- (void)letterViewTapped:(id)sender
{
    UITapGestureRecognizer *recognizer = sender;
    MITDiningMeal *meal = [self.mealsByLetterView objectForKey:[NSString stringWithFormat:@"%p", recognizer.view]];
    NSLog(@"meal: %@", meal.name);
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
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:currentDateWithoutTime];
    
    if ([[date dateWithoutTime] isEqualToDate:currentDateWithoutTime]) {
        return [NSString stringWithFormat:@"Today %i", comps.day];
    } else if ([[date dateWithoutTime] timeIntervalSince1970] == ([currentDateWithoutTime timeIntervalSince1970] - 60 * 60 * 24)) {
        return [NSString stringWithFormat:@"Yesterday %i", comps.day];
    } else if ([[date dateWithoutTime] timeIntervalSince1970] == ([currentDateWithoutTime timeIntervalSince1970] + 60 * 60 * 24)) {
        return [NSString stringWithFormat:@"Tomorrow %i", comps.day];
    } else {
        return [mealDateFormatter stringFromDate:date];
    }
}

@end
