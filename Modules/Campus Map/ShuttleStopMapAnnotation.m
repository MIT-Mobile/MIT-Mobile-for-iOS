
#import "ShuttleStopMapAnnotation.h"


@implementation ShuttleStopMapAnnotation
@synthesize shuttleStop = _shuttleStop;

-(id) initWithShuttleStop:(ShuttleStop*)shuttleStop
{
	self = [super init];
	if (self) {
		_shuttleStop = shuttleStop;
	}
	
	return self;
}


-(CLLocationCoordinate2D) coordinate
{
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = _shuttleStop.latitude;
	coordinate.longitude = _shuttleStop.longitude;
	
	return coordinate;
}

-(NSString*) title
{
	return _shuttleStop.title;
}

-(NSString*) subtitle
{
	return _subtitle;
}

-(void) setSubtitle:(NSString*)subtitle
{
	_subtitle = subtitle;
}

@end
