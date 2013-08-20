#import "ShuttleStopMapAnnotation.h"

@implementation ShuttleStopMapAnnotation
- (id)initWithShuttleStop:(ShuttleStop*)shuttleStop
{
	self = [super init];
	if (self) {
		_shuttleStop = shuttleStop;
	}
	
	return self;
}


- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = self.shuttleStop.latitude;
	coordinate.longitude = self.shuttleStop.longitude;
	
	return coordinate;
}

- (NSString*)title
{
	return self.shuttleStop.title;
}

@end
