#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITShuttleRoute, MITShuttleVehicleList;

@interface MITShuttleVehicle : NSManagedObject

@property (nonatomic, retain) NSNumber * heading;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * secondsSinceReport;
@property (nonatomic, retain) NSNumber * speedKph;
@property (nonatomic, retain) MITShuttleRoute *route;
@property (nonatomic, retain) MITShuttleVehicleList *vehicleList;

@end
