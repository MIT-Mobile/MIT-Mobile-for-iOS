#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttleRoute, MITShuttleVehicleList, MITShuttlePrediction;

@interface MITShuttleVehicle : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSNumber * heading;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * secondsSinceReport;
@property (nonatomic, retain) NSNumber * speedKph;
@property (nonatomic, retain) MITShuttleRoute *route;
@property (nonatomic, retain) MITShuttleVehicleList *vehicleList;
@property (nonatomic, retain) NSSet *predictions;

@end

@interface MITShuttleVehicle (CoreDataGeneratedAccessors)
- (void)addPredictionsObject:(MITShuttlePrediction *)value;
- (void)removePredictionsObject:(MITShuttlePrediction *)value;
- (void)addPredictions:(NSSet *)value;
- (void)removePredictions:(NSSet *)value;

@end
