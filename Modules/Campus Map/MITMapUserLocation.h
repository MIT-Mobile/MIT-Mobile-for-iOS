
// This class represents the MIT Map anaolgue of the MKUserLocation class of the MKMapKit
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MITMapUserLocation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D _coordinate;
}

-(void) updateToCoordinate:(CLLocationCoordinate2D)coordinate;


@end
