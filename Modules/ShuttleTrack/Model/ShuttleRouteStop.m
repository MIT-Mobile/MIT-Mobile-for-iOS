#import "ShuttleRouteStop.h"
#import "ShuttleStopLocation.h"
#import "ShuttleRouteCache.h"

@implementation ShuttleRouteStop 

@dynamic path;
@dynamic order;
@dynamic stopLocation;
@dynamic route;

- (NSString *)stopID
{
	return ((ShuttleStopLocation *)self.stopLocation).stopID;
}

- (NSString *)routeID
{
	return ((ShuttleRouteCache *)self.route).routeID;
}

@end
