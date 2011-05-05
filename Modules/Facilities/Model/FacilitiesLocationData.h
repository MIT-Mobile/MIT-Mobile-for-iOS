#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MITMobileWebAPI.h"

typedef enum {
    FacilitiesDisplayCategory = 0,
    FacilitiesDisplaySubcategory,
    FacilitiesDisplayLocation,
    FacilitiesDisplayRoom
} FacilitiesDisplayType;

extern const NSString *MITFacilitiesDidLoadNotification;
extern const NSString *MITFacilitiesDidFinishLoadingNotification;

typedef void (^FacilitiesDataAvailableBlock)(void);

@class FacilitiesLocation;

@interface FacilitiesLocationData : NSObject <JSONLoadedDelegate> {
    NSMutableDictionary *_requestsInFlight;
    NSMutableArray *_notificationBlocks;
    dispatch_queue_t _requestUpdateQueue;
    dispatch_group_t _defaultGroup;
}

+ (FacilitiesLocationData*)sharedData;

- (id)init;
- (void)dealloc;

- (NSArray*)allCategories;
- (NSArray*)categoriesWithPredicate:(NSPredicate*)predicate;
- (NSArray*)allLocations;
- (NSArray*)locationsWithPredicate:(NSPredicate*)predicate;
- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId;

- (void)notifyOnDataAvailable:(FacilitiesDataAvailableBlock)completedBlock;

@end
