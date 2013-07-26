#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const FacilitiesDidLoadDataNotification;
extern NSString* const FacilitiesCategoriesKey;
extern NSString* const FacilitiesLocationsKey;
extern NSString* const FacilitiesRoomsKey;
extern NSString* const FacilitiesRepairTypesKey;

typedef void (^FacilitiesDidLoadBlock)(NSString *name, BOOL dataUpdated, id userData);

@class FacilitiesLocation;

@interface FacilitiesLocationData : NSObject
+ (FacilitiesLocationData*)sharedData;

- (id)init;

- (NSArray*)allCategories;

- (NSArray*)allLocations;
- (NSArray*)locationsInCategory:(NSString*)categoryId;
- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId;

- (NSArray*)locationsWithNumber:(NSString*)locationNumber
                        updated:(void (^) (NSArray *results))updatedBlock;

- (NSArray*)locationsWithName:(NSString*)locationName
                      updated:(void (^) (NSArray *results))updatedBlock;

- (NSArray*)roomsForBuilding:(NSString*)bldgnum;
- (NSArray*)roomsMatchingPredicate:(NSPredicate*)predicate;

- (NSArray*)hiddenBuildings;
- (NSArray*)leasedBuildings;

- (NSArray*)allRepairTypes;

- (id)addUpdateObserver:(FacilitiesDidLoadBlock)block;
- (void)removeUpdateObserver:(id)observer;
@end
