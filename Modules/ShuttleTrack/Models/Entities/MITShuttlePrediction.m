#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleStop.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttlePrediction

@dynamic seconds;
@dynamic timestamp;
@dynamic vehicleId;
@dynamic list;
@dynamic stop;
@dynamic vehicle;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"vehicle_id": @"vehicleId",
                                                  @"timestamp": @"timestamp",
                                                  @"seconds": @"seconds"}];
    [mapping addConnectionForRelationship:@"vehicle" connectedBy:@{@"vehicleId": @"identifier"}];
    [mapping setIdentificationAttributes:@[@"vehicleId", @"timestamp"]];
    return mapping;
}

@end
