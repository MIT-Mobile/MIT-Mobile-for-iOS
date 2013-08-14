#import "ShuttleStopLocation.h"
#import "ShuttleRouteCache.h"
#import "ShuttleRouteStop.h"

@implementation ShuttleStopLocation 

@dynamic stopID;
@dynamic title;
@dynamic direction;
@dynamic routeStops;
@dynamic longitude;
@dynamic latitude;

- (void)updateInfo:(NSDictionary *)stopInfo
{
	self.title = stopInfo[@"title"];
	self.direction = stopInfo[@"direction"];
	
	id num = stopInfo[@"lat"];
	if (nil != num && num != [NSNull null])
		self.latitude = [NSNumber numberWithDouble:[num doubleValue]];
	
	num = stopInfo[@"lon"];
	if(nil != num && num != [NSNull null])	
		self.longitude = [NSNumber numberWithDouble:[num doubleValue]];
}

@end
