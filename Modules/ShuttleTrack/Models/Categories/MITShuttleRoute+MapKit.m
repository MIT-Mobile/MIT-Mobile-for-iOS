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

- (BOOL)pathSegmentsAreValid
{
    return [self.pathSegments isKindOfClass:[NSArray class]] &&
           [self.pathSegments count] > 0 &&
           [[self.pathSegments firstObject] isKindOfClass:[NSArray class]];
}

- (NSArray *)pathSegmentPolylines
{
    NSArray *pathSegments = [self.pathSegments isKindOfClass:[NSArray class]] ? self.pathSegments : nil;
    
    NSMutableArray *segmentPolylines = [NSMutableArray arrayWithCapacity:[pathSegments count]];
    
    for (NSInteger i = 0; i < pathSegments.count; i++) {
        NSArray *pathSegment = [pathSegments[i] isKindOfClass:[NSArray class]] ? pathSegments[i] : nil;
        
        if (pathSegment) {
            CLLocationCoordinate2D segmentPoints[pathSegment.count];
            
            for (NSInteger j = 0; j < pathSegment.count; j++) {
                NSArray *pathCoordinateArray = [pathSegment[j] isKindOfClass:[NSArray class]] ? pathSegment[j] : nil;
                
                if (pathCoordinateArray && pathCoordinateArray.count > 1) {
                    NSNumber *longitude = pathCoordinateArray[0];
                    NSNumber *latitude = pathCoordinateArray[1];
                    
                    CLLocationCoordinate2D pathPointCoordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
                    segmentPoints[j] = pathPointCoordinate;
                }
            }
            
            MKPolyline *segmentPolyline = [MKPolyline polylineWithCoordinates:segmentPoints count:pathSegment.count];
            [segmentPolylines addObject:segmentPolyline];
        }
    }
    return [NSArray arrayWithArray:segmentPolylines];
}

@end
