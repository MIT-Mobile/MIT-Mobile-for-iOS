#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningRetailVenue;

@interface MITDiningRetailDay : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSSet *retailHours;

- (NSString *)hoursSummary;
- (NSString *)openClosedStatusRelativeToDate:(NSDate *)date;

@end

@interface MITDiningRetailDay (CoreDataGeneratedAccessors)

- (void)addRetailHoursObject:(MITDiningRetailVenue *)value;
- (void)removeRetailHoursObject:(MITDiningRetailVenue *)value;
- (void)addRetailHours:(NSSet *)values;
- (void)removeRetailHours:(NSSet *)values;

@end
