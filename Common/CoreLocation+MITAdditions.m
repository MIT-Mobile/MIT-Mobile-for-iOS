#import "CoreLocation+MITAdditions.h"

FOUNDATION_EXTERN NSString* NSStringFromCLLocationCoordinate2DAsDMS(CLLocationCoordinate2D coordinate) {
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return nil;
    }
    
    NSMutableString *coordinateString = [[NSMutableString alloc] init];
    {
        CLLocationDegrees latitude = coordinate.latitude;
        double degrees = 0;
        double minutes = fabs(modf(latitude, &degrees) * 60.);
        double seconds = floor(modf(minutes, &minutes) * 60.);
        
        NSString *hemisphere = (degrees >= 0) ? @"N" : @"S";
        [coordinateString appendFormat:@"%d°%d'%d\"%@", (int)fabs(degrees), (int)minutes, (int)seconds, hemisphere];
    }
    
    {
        CLLocationDegrees longitude = coordinate.longitude;
        double degrees = 0;
        double minutes = fabs(modf(longitude, &degrees) * 60.);
        double seconds = floor(modf(minutes, &minutes) * 60.);
        
        NSString *hemisphere = (degrees >= 0) ? @"E" : @"W";
        [coordinateString appendFormat:@", %d°%d'%d\"%@", (int)fabs(degrees), (int)minutes, (int)seconds, hemisphere];
    }
    
    return coordinateString;
}

@implementation CLLocation (MITAdditions)

- (CLLocationDistance)distanceFromCenterOfCampus {
    CLLocationCoordinate2D defaultCenter = DEFAULT_MAP_CENTER;
    CLLocation *centerOfCampus = [[[CLLocation alloc] initWithLatitude:defaultCenter.latitude longitude:defaultCenter.longitude] autorelease];
    CGFloat distance = [self distanceFromLocation:centerOfCampus];
    return distance;
}

- (BOOL)isOnCampus {
    return [self distanceFromCenterOfCampus] <= OUT_OF_BOUNDS_DISTANCE;
}

- (BOOL)isNearCampus {
    return [self distanceFromCenterOfCampus] <= WAY_OUT_OF_BOUNDS_DISTANCE;
}

+ (CLLocationSmootsDistance)smootsForDistance:(CLLocationDistance)distance
{
    return distance * METERS_PER_SMOOT;
}

@end
