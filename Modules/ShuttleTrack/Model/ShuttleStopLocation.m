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
	self.title = [stopInfo objectForKey:@"title"];
	self.direction = [stopInfo objectForKey:@"direction"];
	
	id num = [stopInfo objectForKey:@"lat"];
	if (nil != num && num != [NSNull null])
		self.latitude = [NSNumber numberWithDouble:[num doubleValue]];
	
	num = [stopInfo objectForKey:@"lon"];
	if(nil != num && num != [NSNull null])	
		self.longitude = [NSNumber numberWithDouble:[num doubleValue]];
}

@end
