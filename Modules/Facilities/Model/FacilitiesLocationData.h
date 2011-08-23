#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MITMobileWebAPI.h"

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
- (void)dealloc;

- (NSArray*)allCategories;

- (NSArray*)allLocations;
- (NSArray*)locationsInCategory:(NSString*)categoryId;
- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId;

- (NSArray*)roomsForBuilding:(NSString*)bldgnum;
- (NSArray*)roomsMatchingPredicate:(NSPredicate*)predicate;

- (NSArray*)hiddenBuildings;
- (NSArray*)leasedBuildings;

- (NSArray*)allRepairTypes;

- (void)addObserver:(id)observer withBlock:(FacilitiesDidLoadBlock)block;
- (void)removeObserver:(id)observer;
@end
