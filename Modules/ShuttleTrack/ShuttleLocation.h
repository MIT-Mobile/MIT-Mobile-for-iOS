
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>{

	int _secsSinceReport;
	int _heading;

	CLLocationCoordinate2D _coordinate;
}

@property int secsSinceReport;
@property int heading;

-(id) initWithDictionary:(NSDictionary*)dictionary;

@end
