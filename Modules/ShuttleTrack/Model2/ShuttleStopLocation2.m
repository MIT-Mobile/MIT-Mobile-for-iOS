#import "ShuttleStopLocation2.h"
#import "ShuttleRouteCache2.h"
#import "ShuttleRouteStop2.h"

@implementation ShuttleStopLocation2

@dynamic stopID;
@dynamic title;
@dynamic latitude;
@dynamic longitude;
@dynamic routeStops;

- (void)updateInfo:(NSDictionary *)stopInfo
{
	self.title = [stopInfo objectForKey:@"title"];
	
	id num = [stopInfo objectForKey:@"lat"];
	if (nil != num && num != [NSNull null])
		self.latitude = [NSNumber numberWithDouble:[num doubleValue]];
	
	num = [stopInfo objectForKey:@"lon"];
	if(nil != num && num != [NSNull null])
		self.longitude = [NSNumber numberWithDouble:[num doubleValue]];
}

@end
