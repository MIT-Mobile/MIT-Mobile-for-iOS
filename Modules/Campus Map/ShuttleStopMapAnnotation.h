
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ShuttleStop.h"

@interface ShuttleStopMapAnnotation : NSObject <MKAnnotation>
{
	ShuttleStop* _shuttleStop;
	
	NSString* _subtitle;
}

-(id) initWithShuttleStop:(ShuttleStop*)shuttleStop;

@property (readonly) ShuttleStop* shuttleStop;

-(void) setSubtitle:(NSString*) subtitle;

@end
