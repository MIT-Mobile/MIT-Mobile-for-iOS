#import <Foundation/Foundation.h>

@interface MITDiningMealSummary : NSObject

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSArray *meals;
@property (nonatomic, readonly) NSString *dateRangesString;
@property (nonatomic, readonly) NSString *mealNamesStringsOnSeparateLines;
@property (nonatomic, readonly) NSString *mealTimesStringsOnSeparateLines;

- (BOOL)mealSummaryContainsSameMeals:(MITDiningMealSummary *)mealSummary;

@end
