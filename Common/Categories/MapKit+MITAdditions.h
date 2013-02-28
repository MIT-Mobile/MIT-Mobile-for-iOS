#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

FOUNDATION_EXTERN BOOL MKCoordinateRegionIsValid(MKCoordinateRegion);
FOUNDATION_EXTERN MKCoordinateRegion MKCoordinateRegionForCoordinates(NSSet *coordinateValues);
FOUNDATION_EXTERN MKCoordinateRegion MKCoordinateRegionForCoordinatesWithPadding(NSSet *coordinateValues, CGFloat padding);