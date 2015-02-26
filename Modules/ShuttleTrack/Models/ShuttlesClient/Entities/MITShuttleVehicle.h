#import <Foundation/Foundation.h>
#import <JSONMapping/JSONMapping.h>
#import <Realm/Realm.h>

#import <MapKit/MapKit.h>
#import "MITShuttlePrediction.h"

@class MITShuttleRoute, MITShuttleVehicleList, MITShuttlePrediction;

@interface MITShuttleVehicle : RLMObject <JSONMappableObject, MKAnnotation>

@property NSInteger heading;
@property NSString *identifier;
@property double latitude;
@property double longitude;
@property NSTimeInterval secondsSinceReport;
@property NSInteger speedKph;

@property RLMArray<MITShuttlePrediction> *preds;
@property MITShuttleRoute *route;
//@property (nonatomic, retain) NSString * routeId;
//@property (nonatomic, retain) MITShuttleRoute *route;
//@property (nonatomic, retain) MITShuttleVehicleList *vehicleList;

//+ (RKMapping *)objectMappingFromVehicleList;

@end

RLM_ARRAY_TYPE(MITShuttleVehicle)
