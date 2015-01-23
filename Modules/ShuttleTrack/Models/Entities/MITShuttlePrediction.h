#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttlePredictionList, MITShuttleStop, MITShuttleVehicle;

@interface MITShuttlePrediction : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSNumber * seconds;
@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * vehicleId;
@property (nonatomic, retain) MITShuttlePredictionList *list;
@property (nonatomic, retain) MITShuttleStop *stop;
@property (nonatomic, retain) MITShuttleVehicle *vehicle;

+ (RKMapping *)objectMappingFromStop;
+ (RKMapping *)objectMappingFromPredictionList;

@end
