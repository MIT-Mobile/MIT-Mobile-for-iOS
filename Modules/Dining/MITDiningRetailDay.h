#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningRetailVenue;

@interface MITDiningRetailDay : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString *dateString;
@property (nonatomic, retain) NSString *endTimeString;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *startTimeString;
@property (nonatomic, retain) NSSet *retailHours;

- (NSDate *)startTime;
- (NSDate *)endTime;
- (NSDate *)date;
- (NSString *)hoursSummary;
- (NSString *)statusStringForDate:(NSDate *)date;

@end

@interface MITDiningRetailDay (CoreDataGeneratedAccessors)

- (void)addRetailHoursObject:(MITDiningRetailVenue *)value;
- (void)removeRetailHoursObject:(MITDiningRetailVenue *)value;
- (void)addRetailHours:(NSSet *)values;
- (void)removeRetailHours:(NSSet *)values;

@end
