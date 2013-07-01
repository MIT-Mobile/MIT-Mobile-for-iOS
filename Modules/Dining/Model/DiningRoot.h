#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HouseVenue, RetailVenue;

@interface DiningRoot : NSManagedObject

@property (nonatomic, retain) NSString * announcementsHTML;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSSet *links;
@property (nonatomic, retain) NSSet *houseVenues;
@property (nonatomic, retain) NSSet *retailVenues;

+ (DiningRoot *)newRootWithDictionary:(NSDictionary *)dict;

@end

@interface DiningRoot (CoreDataGeneratedAccessors)

- (void)addLinksObject:(NSManagedObject *)value;
- (void)removeLinksObject:(NSManagedObject *)value;
- (void)addLinks:(NSSet *)values;
- (void)removeLinks:(NSSet *)values;

- (void)addHouseVenuesObject:(HouseVenue *)value;
- (void)removeHouseVenuesObject:(HouseVenue *)value;
- (void)addHouseVenues:(NSSet *)values;
- (void)removeHouseVenues:(NSSet *)values;

- (void)addRetailVenuesObject:(RetailVenue *)value;
- (void)removeRetailVenuesObject:(RetailVenue *)value;
- (void)addRetailVenues:(NSSet *)values;
- (void)removeRetailVenues:(NSSet *)values;

@end
