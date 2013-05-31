#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VenueLocation;
@class RetailDay;

@interface RetailVenue : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *shortName;
@property (nonatomic, retain) NSString *descriptionHTML;
@property (nonatomic, retain) NSArray *paymentMethods;
@property (nonatomic, retain) NSArray *cuisines;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *homepageURL;
@property (nonatomic, retain) NSString *menuURL;
@property (nonatomic, retain) NSString *iconURL;
@property (nonatomic, retain) NSString *building;
@property (nonatomic, retain) NSString *sortableBuilding;
@property (nonatomic, retain) VenueLocation *location;
@property (nonatomic, retain) NSSet *days;

+ (RetailVenue *)newVenueWithDictionary:(NSDictionary *)dict;
- (BOOL)isOpenNow;
- (NSString *)hoursToday;
- (RetailDay *)dayForDate:(NSDate *)date;
+ (NSDate *)fakeDate;

@end

@interface RetailVenue (CoreDataGeneratedAccessors)

- (void)addDaysObject:(RetailDay *)value;
- (void)removeDaysObject:(RetailDay *)value;
- (void)addDays:(NSSet *)values;
- (void)removeDays:(NSSet *)values;

@end
