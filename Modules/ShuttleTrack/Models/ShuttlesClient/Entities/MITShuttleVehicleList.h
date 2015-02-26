#import <Foundation/Foundation.h>
#import <JSONMapping/JSONMapping.h>
#import <Realm/Realm.h>
#import "MITShuttleVehicle.h"

@class MITShuttleVehicle, MITShuttleRoute;

@interface MITShuttleVehicleList : RLMObject <JSONMappableObject>

@property NSString *agency;
@property NSString *routeId;
@property NSString *routeURL;
@property RLMArray<MITShuttleVehicle> *vehicles;
@property BOOL scheduled;
@property BOOL predictable;

//@property (nonatomic, retain) MITShuttleRoute *route;

//+ (RKMapping *)objectMappingFromDetail;
//+ (RKMapping *)objectMappingFromRoute;

@end

RLM_ARRAY_TYPE(MITShuttleVehicleList)
