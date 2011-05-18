#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MITMobileWebAPI.h"

extern NSString* const FacilitiesDidLoadDataNotification;
extern NSString* const FacilitiesCategoriesKey;
extern NSString* const FacilitiesLocationsKey;
extern NSString* const FacilitiesRoomsKey;

typedef void (^FacilitiesDidLoadBlock)(NSString *name, BOOL dataUpdated, id userData);

@class FacilitiesLocation;

@interface FacilitiesLocationData : NSObject <JSONLoadedDelegate> {
    NSMutableDictionary *_requestsInFlight;
    NSMutableDictionary *_notificationBlocks;
    dispatch_queue_t _requestUpdateQueue;
}

+ (FacilitiesLocationData*)sharedData;

- (id)init;
- (void)dealloc;

- (NSArray*)allCategories;
- (NSArray*)categoriesMatchingPredicate:(NSPredicate*)predicate;

- (NSArray*)allLocations;
- (NSArray*)locationsMatchingPredicate:(NSPredicate*)predicate;
- (NSArray*)locationsInCategory:(NSString*)categoryId;
- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId;

- (NSArray*)roomsForBuilding:(NSString*)bldgnum;
- (NSArray*)roomsMatchingPredicate:(NSPredicate*)predicate;

- (void)addObserver:(id)observer withBlock:(FacilitiesDidLoadBlock)block;
- (void)removeObserver:(id)observer;

@end
