#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import <JSONMapping/JSONMapping.h>
//#import "MITShuttleStop.h"

@class MITShuttlePredictionList, MITShuttleStop, MITShuttleVehicle;

@interface MITShuttlePrediction : RLMObject <JSONMappableObject>

//@property NSString * stopId;
//@property NSString * routeId;
@property NSTimeInterval seconds;
@property NSTimeInterval timestamp;
@property NSString *vehicleId;

// Computed
@property (readonly) MITShuttleVehicle *vehicle;
@end

RLM_ARRAY_TYPE(MITShuttlePrediction)