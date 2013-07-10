#import "MapKit+MITAdditions.h"
#import "CoreLocation+MITAdditions.h"

const double MITMapRegionDefaultPadding = 0.40;
const CLLocationDistance MITMapRegionDefaultMinimumRegionSize = 25.;

const MKCoordinateRegion MKCoordinateRegionInvalid = {{.longitude = CGFLOAT_MAX,
    .latitude = CGFLOAT_MAX},
    {.latitudeDelta = CGFLOAT_MAX,
        .longitudeDelta = CGFLOAT_MAX}};

MKCoordinateRegion MKCoordinateRegionForCoordinates(NSSet *coordinateValues) {
    return MKCoordinateRegionForCoordinatesWithPadding(coordinateValues,MITMapRegionDefaultPadding,MITMapRegionDefaultMinimumRegionSize);
}

MKCoordinateRegion MKCoordinateRegionForCoordinatesWithPadding(NSSet *coordinateValues, CGFloat paddingPercent, CLLocationDistance minimumRegionSize) {
    NSMutableArray *longitudes = [NSMutableArray array];
    NSMutableArray *latitudes = [NSMutableArray array];
    
    if ([coordinateValues count] == 0) {
        DDLogCWarn(@"warning: attempting to create a map region for no coordinates");
        return MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(CGFLOAT_MAX,CGFLOAT_MAX),
                                                  0,0);
    }
    
    // Ensure that the padding is bounded to [0,1]
    if (paddingPercent < 0.0) {
        paddingPercent = 0.0;
    } else if (paddingPercent > 1.0) {
        paddingPercent = 1.0;
    }
    
    for (NSValue *value in coordinateValues) {
        CLLocationCoordinate2D coordinate = [value CLLocationCoordinateValue];
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            [longitudes addObject:@(coordinate.longitude)];
            [latitudes addObject:@(coordinate.latitude)];
        }
    }
    
    if ([longitudes count] != [latitudes count]) {
        DDLogCError(@"error creating region due invalid coordinate data (%ld != %ld)",
                    (unsigned long)[longitudes count],
                    (unsigned long)[latitudes count]);
        return MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(CGFLOAT_MAX,CGFLOAT_MAX),
                                                  0,0);
    } else if ([longitudes count] == 1) {
        return MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake([latitudes[0] doubleValue], [longitudes[0] doubleValue]),
                                                  minimumRegionSize,
                                                  minimumRegionSize);
    }
    
    [longitudes sortUsingSelector:@selector(compare:)];
    [latitudes sortUsingSelector:@selector(compare:)];
    
    CLLocationDegrees maxLongitude = [[longitudes lastObject] doubleValue];
    CLLocationDegrees minLongitude = [longitudes[0] doubleValue];
    CLLocationDegrees maxLatitude = [[latitudes lastObject] doubleValue];
    CLLocationDegrees minLatitude = [latitudes[0] doubleValue];
    
    CLLocationDegrees latitudeDelta = fabs(maxLatitude - minLatitude);
    CLLocationDegrees longitudeDelta = fabs(maxLongitude - minLongitude);
    CLLocationCoordinate2D centerPoint = CLLocationCoordinate2DMake(minLatitude + (latitudeDelta / 2.0),
                                                                    minLongitude + (longitudeDelta / 2.0));
    latitudeDelta += latitudeDelta * paddingPercent;
    longitudeDelta += longitudeDelta * paddingPercent;
    
    return MKCoordinateRegionMake(centerPoint, MKCoordinateSpanMake(latitudeDelta,longitudeDelta));
}


BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region) {
    // Keep an eye on this. Comparing floating point to 0 is
    // generally a bad idea
    return (CLLocationCoordinate2DIsValid(region.center) &&
            (region.span.latitudeDelta > 0.0) &&
            (region.span.longitudeDelta > 0.0));
}