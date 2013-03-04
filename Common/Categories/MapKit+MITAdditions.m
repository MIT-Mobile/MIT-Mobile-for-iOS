#import "MapKit+MITAdditions.h"
#import "CoreLocation+MITAdditions.h"

#define MITMK_DEFAULT_REGION_PADDING (0.1)
#define MITMK_MINIMUM_REGION_METERS (25)

MKCoordinateRegion MKCoordinateRegionForCoordinates(NSSet *coordinateValues) {
    return MKCoordinateRegionForCoordinatesWithPadding(coordinateValues, MITMK_DEFAULT_REGION_PADDING);
}

MKCoordinateRegion MKCoordinateRegionForCoordinatesWithPadding(NSSet *coordinateValues, CGFloat padding) {
    NSMutableArray *longitudes = [NSMutableArray array];
    NSMutableArray *latitudes = [NSMutableArray array];
    
    if ([coordinateValues count] == 0) {
        DDLogCWarn(@"warning: attempting to create a map region for no coordinates");
        return MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(CGFLOAT_MAX,CGFLOAT_MAX),
                                                  0,0);
    }
    
    // Ensure that the padding is bounded to [0,1]
    if (padding < 0.0) {
        padding = 0.0;
    } else if (padding > 1.0) {
        padding = 1.0;
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
        return MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake([latitudes[0] doubleValue],
                                                                 [longitudes[0] doubleValue]),
                                                  MITMK_MINIMUM_REGION_METERS,MITMK_MINIMUM_REGION_METERS);
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
    
    return MKCoordinateRegionMake(centerPoint, MKCoordinateSpanMake(latitudeDelta * (1.0 + padding), longitudeDelta * (1.0 + padding)));
}


BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region) {
    // Keep an eye on this. Comparing floating point to 0 is
    // generally a bad idea
    return (CLLocationCoordinate2DIsValid(region.center) &&
            (region.span.latitudeDelta > 0.0) &&
            (region.span.longitudeDelta > 0.0));
}