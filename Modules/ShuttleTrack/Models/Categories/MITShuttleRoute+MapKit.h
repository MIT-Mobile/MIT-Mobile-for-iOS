#import "MITShuttleRoute.h"
#import <MapKit/MapKit.h>

@interface MITShuttleRoute (MapKit)

- (MKCoordinateRegion)mapRegionWithPaddingFactor:(CGFloat)paddingFactor;

@end
