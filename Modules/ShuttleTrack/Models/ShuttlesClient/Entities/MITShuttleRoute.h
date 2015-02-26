#import <Foundation/Foundation.h>

#import <Realm/Realm.h>
#import <JSONMapping/JSONMapping.h>
#import "MITShuttleStop.h"
#import "MITShuttleVehicle.h"
#import "MITMapPathSegment.h"
#import "MITMapBoundingBox.h"

@class MITShuttleVehicleList;

typedef NS_ENUM(NSUInteger, MITShuttleRouteStatus) {
    MITShuttleRouteStatusNotInService = 0,
    MITShuttleRouteStatusInService,
    MITShuttleRouteStatusUnknown
};

@interface MITShuttleRoute : RLMObject <JSONMappableObject>

@property NSString *agency;
@property NSString *identifier;
@property MITMapBoundingBox *pathBoundingBox;
@property RLMArray<MITMapPathSegment> *pathSegments;
@property BOOL predictable;
@property NSString *predictionsURL;
@property NSString *routeDescription;
@property BOOL scheduled;
@property NSString *title;
@property NSString *url;
@property NSString *vehiclesURL;
@property RLMArray<MITShuttleStop> *stops;
@property RLMArray<MITShuttleVehicle> *vehicles;

// Set manually
@property NSDate *updatedTime;
@property MITShuttleVehicleList *vehicleList;
@property (readonly) MITShuttleRouteStatus status;

- (BOOL)isNextStop:(MITShuttleStop *)stop;
- (MITShuttleStop *)nextStopForVehicle:(MITShuttleVehicle *)vehicle;
@property NSInteger order;

- (NSArray *)nearestStopsWithCount:(NSInteger)count;
@end

RLM_ARRAY_TYPE(MITShuttleRoute)

