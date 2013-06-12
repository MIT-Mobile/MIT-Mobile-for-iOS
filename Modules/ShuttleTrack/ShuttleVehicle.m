#import "ShuttleVehicle.h"

@implementation ShuttleVehicle

@synthesize vehicleID = _vehicleID;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@synthesize heading = _heading;
@synthesize speed = _speed;
@synthesize lastReport = _lastReport;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if (self != nil) {
		[self updateInfo:dict];
	}
	return self;
}

- (void)updateInfo:(NSDictionary *)vehiclesInfo
{
    self.vehicleID = [vehiclesInfo objectForKey:@"id"];
    self.latitude = [[vehiclesInfo objectForKey:@"lat"] doubleValue];
    self.longitude = [[vehiclesInfo objectForKey:@"lon"] doubleValue];
    self.heading = [[vehiclesInfo objectForKey:@"heading"]intValue];
    self.speed = [[vehiclesInfo objectForKey:@"speed" ] doubleValue];
    self.lastReport = [[vehiclesInfo objectForKey:@"lastReport"] intValue];
}

@end
