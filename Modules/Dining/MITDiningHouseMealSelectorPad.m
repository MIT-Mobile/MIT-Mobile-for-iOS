#import "MITDiningHouseMealSelectorPad.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "MITDiningHouseVenue.h"
#import "Foundation+MITAdditions.h"
#import "MITAdditions.h"

static CGFloat const MITDiningHouseMealSelectorActiveSwipeSelectionScale = 1.25;
static CGFloat const MITDiningHouseMealSelectorHitPointPadding = 30.0;
static CGFloat const MITDiningHouseMealSelectorHighlightOffset = -30.0;
static NSTimeInterval const MITDiningHouseMealSelectorLongPressTimerDuration = 0.4;

@interface MITDiningHouseMealSelectorPad ()

@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSDictionary *dateKeyedMeals;
@property (nonatomic, strong) NSDictionary *mealsByLetterView;
@property (nonatomic, strong) NSDictionary *letterViewsByDate;
@property (nonatomic, strong) NSDictionary *dateLabelsByDate;
@property (nonatomic, strong) UILabel *selectedMealNameLabel;
@property (nonatomic, strong) UIView *selectedMealBackground;
@property (nonatomic, weak) UILabel *currentlySelectedLetterView;

@property (nonatomic, strong) NSArray *mealLetterViews;
@property (nonatomic, weak) UILabel *currentlyHighlightedLetterView;
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic) CGFloat letterViewsCenterY;
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

- (void)selectMeal:(NSString *)mealName onDate:(NSDate *)date
{
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
    [self mealSelected:mealName onDate:date];
}

#pragma mark - Private Methods

- (void)selectLetterView:(UILabel *)letterView
{
    letterView.textColor = [UIColor whiteColor];
    self.selectedMealBackground.center = letterView.center;
    self.selectedMealBackground.hidden = NO;
    [self bringSubviewToFront:letterView];
    
    
    MITDiningMeal *meal = [self.mealsByLetterView objectForKey:[NSString stringWithFormat:@"%p", letterView]];
    self.selectedMealNameLabel.text = [meal titleCaseName];
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
    NSMutableArray *mealLetterViews = [NSMutableArray array];
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
            [self addSubview:mealLetterLabel];
            
            [newMealsByLetterView setObject:meal forKey:[NSString stringWithFormat:@"%p", mealLetterLabel]];
            [letterViewsForCurrentDate addObject:mealLetterLabel];
            [mealLetterViews addObject:mealLetterLabel];
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
    self.mealLetterViews = [NSArray arrayWithArray:mealLetterViews];
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
            if (letterView == self.currentlyHighlightedLetterView) {
                CGPoint center = letterView.center;
                center.y += MITDiningHouseMealSelectorHighlightOffset;
                letterView.center = center;
            }
            
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
        self.letterViewsCenterY = self.currentlySelectedLetterView.center.y;
        [self bringSubviewToFront:self.currentlySelectedLetterView];
        
        self.selectedMealNameLabel.frame = CGRectMake(0, self.bounds.size.height - selectedMealNameLabelHeight - verticalPadding, self.selectedMealNameLabel.frame.size.width, self.selectedMealNameLabel.frame.size.height);
        CGPoint selectedMealNameLabelCenter = self.selectedMealNameLabel.center;
        selectedMealNameLabelCenter.x = self.currentlySelectedLetterView.center.x;
        self.selectedMealNameLabel.center = selectedMealNameLabelCenter;
    }
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

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouch:touches.anyObject isDragging:NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endLongPressTimer];
    [self handleTouch:touches.anyObject isDragging:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesFinished];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesFinished];
}

- (void)handleTouch:(UITouch *)touch isDragging:(BOOL)isDragging
{
    CGPoint location = [touch locationInView:self];
    for (UILabel *v in self.mealLetterViews) {
        CGRect frame = v.frame;
        frame.origin.y -= MITDiningHouseMealSelectorHitPointPadding;
        frame.size.height += MITDiningHouseMealSelectorHitPointPadding * 2.0;
        if (CGRectContainsPoint(frame, location)) {
            if (v != self.currentlySelectedLetterView) {
                [self deselectLetterView:self.currentlySelectedLetterView];
                [self selectLetterView:v];
                if (isDragging) {
                    [self highlightLetterView:v];
                } else {
                    [self startLongPressTimer];
                }
            }
            break;
        }
    }
}

- (void)highlightLetterView:(UILabel *)letterView {
    self.currentlyHighlightedLetterView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    CGPoint currentCenter = self.currentlySelectedLetterView.center;
    currentCenter.y = self.letterViewsCenterY;
    self.currentlyHighlightedLetterView.center = currentCenter;
    
    self.currentlyHighlightedLetterView = letterView;
    CGFloat scale = MITDiningHouseMealSelectorActiveSwipeSelectionScale;
    letterView.transform = CGAffineTransformMakeScale(scale, scale);
    CGPoint center = letterView.center;
    center.y += MITDiningHouseMealSelectorHighlightOffset;
    letterView.center = center;
    self.selectedMealBackground.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)touchesFinished
{
    [self endLongPressTimer];
    [self updateForCurrentlySelectedLetterView];
    UILabel *currentlyHighlightedLetterView = self.currentlyHighlightedLetterView;
    self.currentlyHighlightedLetterView = nil;
    [UIView animateWithDuration:0.25 animations:^{
        self.selectedMealBackground.transform = CGAffineTransformMakeScale(1.0, 1.0);
        currentlyHighlightedLetterView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        CGPoint center = currentlyHighlightedLetterView.center;
        center.y = self.letterViewsCenterY;
        currentlyHighlightedLetterView.center = center;
    }];
}

- (void)startLongPressTimer
{
    [self endLongPressTimer];
    self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:MITDiningHouseMealSelectorLongPressTimerDuration
                                                           target:self
                                                         selector:@selector(longPressTimerFired)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)endLongPressTimer
{
    [self.longPressTimer invalidate];
    self.longPressTimer = nil;
}

- (void)longPressTimerFired
{
    [self highlightLetterView:self.currentlySelectedLetterView];
}

- (void)updateForCurrentlySelectedLetterView
{
    MITDiningMeal *meal = [self.mealsByLetterView objectForKey:[NSString stringWithFormat:@"%p", self.currentlySelectedLetterView]];
    [self mealSelected:meal.name onDate:[self dateForMeal:meal]];
}

@end
