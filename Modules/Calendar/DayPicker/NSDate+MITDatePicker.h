#import <Foundation/Foundation.h>

@interface NSDate (MITDatePicker)

- (BOOL)dp_isEqualToDateIgnoringTime:(NSDate *)aDate;
- (NSArray *)dp_datesInWeek;
- (NSDate *)dp_startOfWeek;
- (NSDate *)dp_dateByAddingWeek;
- (NSDate *)dp_dateBySubtractingWeek;
- (NSDate *)dp_startOfDay;
- (BOOL)dp_dateFallsBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@end
