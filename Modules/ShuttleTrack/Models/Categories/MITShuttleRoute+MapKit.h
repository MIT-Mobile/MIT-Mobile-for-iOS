#import "MITShuttleRoute.h"
#import <MapKit/MapKit.h>

@interface MITShuttleRoute (MapKit)

- (BOOL)pathSegmentsAreValid;
- (NSArray *)pathSegmentPolylines;
- (MKCoordinateRegion)encompassingMapRegion;

@end
