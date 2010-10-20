
#import "MITMapUserLocation.h"


@implementation MITMapUserLocation
@synthesize coordinate = _coordinate;

-(void) updateToCoordinate:(CLLocationCoordinate2D)coordinate
{
	_coordinate = coordinate;
}


@end
