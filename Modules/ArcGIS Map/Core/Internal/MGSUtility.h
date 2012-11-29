#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

FOUNDATION_EXPORT AGSPoint* AGSPointFromCLLocationCoordinate(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D CLLocationCoordinateFromAGSPoint(AGSPoint *point);