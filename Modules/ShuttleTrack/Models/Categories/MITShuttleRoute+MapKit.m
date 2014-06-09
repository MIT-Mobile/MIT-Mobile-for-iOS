#import "MITShuttleRoute+MapKit.h"

@implementation MITShuttleRoute (MapKit)

- (MKCoordinateRegion)mapRegionWithPaddingFactor:(CGFloat)paddingFactor
{
    NSNumber *bottomLeftLongitude = self.pathBoundingBox[0];
    NSNumber *bottomLeftLatitude = self.pathBoundingBox[1];
    NSNumber *topRightLongitude = self.pathBoundingBox[2];
    NSNumber *topRightLatitude = self.pathBoundingBox[3];
    
    CLLocationDegrees latitudeDelta = fabs([topRightLatitude doubleValue] - [bottomLeftLatitude doubleValue]);
    CLLocationDegrees longitudeDelta = fabs([topRightLongitude doubleValue] - [bottomLeftLongitude doubleValue]);
    CLLocationDegrees latitudePadding = paddingFactor * latitudeDelta;
    CLLocationDegrees longitudePadding = paddingFactor * longitudeDelta;
    
    CLLocationDegrees middleLatitude = ([topRightLatitude doubleValue] + [bottomLeftLatitude doubleValue]) / 2;
    CLLocationDegrees middleLongitude = ([topRightLongitude doubleValue] + [bottomLeftLongitude doubleValue]) / 2;
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(middleLatitude, middleLongitude);
    
    MKCoordinateSpan boundingBoxSpan = MKCoordinateSpanMake(latitudeDelta + latitudePadding, longitudeDelta + longitudePadding);
    return MKCoordinateRegionMake(centerCoordinate, boundingBoxSpan);
}

@end
