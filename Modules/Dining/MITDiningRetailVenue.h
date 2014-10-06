#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningLocation, MITDiningRetailDay, MITDiningVenues;

@interface MITDiningRetailVenue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) id cuisine;
@property (nonatomic, retain) NSString * descriptionHTML;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSString * homepageURL;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * menuHTML;
@property (nonatomic, retain) NSString * menuURL;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id payment;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSOrderedSet *hours;
@property (nonatomic, retain) MITDiningLocation *location;
@property (nonatomic, retain) MITDiningVenues *venues;

- (BOOL)isOpenNow;
- (MITDiningRetailDay *)retailDayForDate:(NSDate *)date;
- (NSString *)hoursToday;

@end

@interface MITDiningRetailVenue (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningRetailDay *)value inHoursAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHoursAtIndex:(NSUInteger)idx;
- (void)insertHours:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHoursAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHoursAtIndex:(NSUInteger)idx withObject:(MITDiningRetailDay *)value;
- (void)replaceHoursAtIndexes:(NSIndexSet *)indexes withHours:(NSArray *)values;
- (void)addHoursObject:(MITDiningRetailDay *)value;
- (void)removeHoursObject:(MITDiningRetailDay *)value;
- (void)addHours:(NSOrderedSet *)values;
- (void)removeHours:(NSOrderedSet *)values;
@end
