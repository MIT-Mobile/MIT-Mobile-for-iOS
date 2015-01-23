#import "MITShuttleRoute+MapKit.h"

static double const kMITShuttleRouteBoundingBoxPaddingFactor = 0.15;

@implementation MITShuttleRoute (MapKit)

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

- (MKCoordinateRegion)encompassingMapRegion
{
    NSArray *coords = [self coordsForPath];
    return [self regionForCoords:coords withPaddingFactor:kMITShuttleRouteBoundingBoxPaddingFactor];
}

- (MKCoordinateRegion)regionForCoords:(NSArray *)coords withPaddingFactor:(CGFloat)paddingFactor {
    
    CLLocationDegrees minLat = 90.0;
    CLLocationDegrees maxLat = -90.0;
    CLLocationDegrees minLon = 180.0;
    CLLocationDegrees maxLon = -180.0;
    
    for (NSValue *val in coords) {
        CLLocationCoordinate2D coord = [val MKCoordinateValue];
        if (coord.latitude < minLat) {
            minLat = coord.latitude;
        }
        if (coord.longitude < minLon) {
            minLon = coord.longitude;
        }
        if (coord.latitude > maxLat) {
            maxLat = coord.latitude;
        }
        if (coord.longitude > maxLon) {
            maxLon = coord.longitude;
        }
    }
    
    CLLocationDegrees latDelta = (maxLat - minLat);
    CLLocationDegrees latPadding = latDelta * paddingFactor;
    latDelta += latPadding;
    CLLocationDegrees lonDelta = (maxLon - minLon);
    CLLocationDegrees lonPadding = lonDelta * paddingFactor;
    lonDelta += lonPadding;
    
    CLLocationDegrees latitudeOffset = fabs(latDelta / 2.0);
    CLLocationDegrees longitudeOffset = fabs(lonDelta / 2.0);
    
    minLat -= latitudeOffset;
    maxLat += latitudeOffset;
    minLon -= longitudeOffset;
    maxLon += longitudeOffset;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(latDelta, lonDelta);
    
    CLLocationDegrees middleLatitude = (maxLat + minLat) / 2;
    CLLocationDegrees middleLongitude = (maxLon + minLon) / 2;
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(middleLatitude, middleLongitude);
    
    return MKCoordinateRegionMake(centerCoordinate, span);
}

- (NSArray *)coordsForPath
{
    NSMutableArray *coordinates = [NSMutableArray array];
    NSArray *pathSegments = self.pathSegments;
    for (NSInteger i = 0; i < pathSegments.count; i++) {
        NSArray *pathSegment = [pathSegments[i] isKindOfClass:[NSArray class]] ? pathSegments[i] : nil;
        if (pathSegment) {
            for (NSInteger j = 0; j < pathSegment.count; j++) {
                NSArray *pathCoordinateArray = [pathSegment[j] isKindOfClass:[NSArray class]] ? pathSegment[j] : nil;
                
                if (pathCoordinateArray && pathCoordinateArray.count > 1) {
                    NSNumber *longitude = pathCoordinateArray[0];
                    NSNumber *latitude = pathCoordinateArray[1];
                    CLLocationCoordinate2D pathPointCoordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
                    NSValue *coordVal = [NSValue valueWithMKCoordinate:pathPointCoordinate];
                    [coordinates addObject:coordVal];
                }
            }
            
        }
    }
    return coordinates;
}

@end
