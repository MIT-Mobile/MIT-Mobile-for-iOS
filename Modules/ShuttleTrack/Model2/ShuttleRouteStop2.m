#import "ShuttleRouteStop2.h"
#import "ShuttleRouteCache2.h"
#import "ShuttleStopLocation2.h"


@implementation ShuttleRouteStop2

@dynamic order;
@dynamic stopLocation;
@dynamic route;

- (NSString *)stopID
{
	return ((ShuttleStopLocation2 *)self.stopLocation).stopID;
}

- (NSString *)routeID
{
	return ((ShuttleRouteCache2 *)self.route).routeID;
}

@end
