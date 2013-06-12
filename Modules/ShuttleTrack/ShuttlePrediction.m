#import "ShuttlePrediction.h"

@implementation ShuttlePrediction
@synthesize vehicleID = _vehicleID;
@synthesize timestamp = _timestamp;
@synthesize seconds = _seconds;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if (self != nil) {
		[self updateInfo:dict];
	}
	return self;
}

- (void)updateInfo:(NSDictionary *)predictionInfo
{
    self.vehicleID = [predictionInfo objectForKey:@"vehicle_id"];
    self.timestamp = [[predictionInfo objectForKey:@"timestamp"] unsignedLongLongValue];
    self.seconds= [[predictionInfo objectForKey:@"seconds"] intValue];
}

@end
