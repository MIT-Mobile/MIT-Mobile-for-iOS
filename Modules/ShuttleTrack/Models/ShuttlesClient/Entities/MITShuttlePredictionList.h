#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import <JSONMapping/JSONMapping.h>
#import "MITShuttlePrediction.h"

@class MITShuttleRoute;

@interface MITShuttlePredictionList : RLMObject <JSONMappableObject>

@property NSString *routeId;
@property NSString *routeURL;
@property NSString *routeTitle;
@property NSString *stopId;
@property NSString *stopURL;
@property NSString *stopTitle;
// TODO: Make sure old predictions are removed or updated properly
@property RLMArray<MITShuttlePrediction> *predictions;

// Added manually, not from server.
@property NSDate *updatedTime;
@property NSString *routeAndStopIdTuple;

// Computed Relationships
@property (readonly) MITShuttleStop *stop;
@property (readonly) MITShuttleRoute *route;

@end
