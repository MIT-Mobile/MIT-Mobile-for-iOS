
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ShuttleStop.h"

@interface ShuttleStopMapAnnotation : NSObject <MKAnnotation>
@property (readonly) ShuttleStop* shuttleStop;
@property (nonatomic,copy) NSString *subtitle;

- (id)initWithShuttleStop:(ShuttleStop*)shuttleStop;
@end
