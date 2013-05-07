#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VenueLocation;

@interface HouseVenue : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) id iconImage;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) id paymentMethods;
@property (nonatomic, retain) NSSet *menuDays;
@property (nonatomic, retain) VenueLocation *location;

+ (HouseVenue *)newVenueWithDictionary:(NSDictionary *)dict;

@end

@interface HouseVenue (CoreDataGeneratedAccessors)

- (void)addMenuDaysObject:(NSManagedObject *)value;
- (void)removeMenuDaysObject:(NSManagedObject *)value;
- (void)addMenuDays:(NSSet *)values;
- (void)removeMenuDays:(NSSet *)values;

@end
