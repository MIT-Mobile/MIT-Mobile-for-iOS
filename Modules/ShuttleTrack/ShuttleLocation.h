
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>

@property int secsSinceReport;
@property int heading;

-(id) initWithDictionary:(NSDictionary*)dictionary;

@end
