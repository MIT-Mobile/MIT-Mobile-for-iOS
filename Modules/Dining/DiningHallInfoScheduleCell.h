
#import <UIKit/UIKit.h>
#import "MITDiningInfoScheduleCell.h"

@interface DiningHallInfoScheduleCell : MITDiningInfoScheduleCell

@property (nonatomic, strong) NSArray * scheduleInfo;
//
//                          schedule info is array of dictionaries with one of the following formats:
//                                  @{@"mealName": mealName, @"mealSpan": meal.message};        
//                                  @{@"mealName": mealName, @"mealSpan": mealSpan}             // where mealSpan is formatted time string, and mealName is already in capitalized format
//                                                                                              // created in DiningHallInfoViewController's scheduleDictionaryForMeal: method


- (void) setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate;

+ (CGFloat)heightForCellWithScheduleInfo:(NSArray *)scheduleInfo withTopPadding:(BOOL)includeTopPadding;

@end
