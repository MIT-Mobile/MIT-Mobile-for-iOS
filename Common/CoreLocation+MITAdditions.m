#import "CoreLocation+MITAdditions.h"

const CLLocationCoordinate2D CLLocationCoordinate2DInvalid = {.longitude = CGFLOAT_MAX, .latitude = CGFLOAT_MAX};

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

@end


@implementation NSValue (CL_MITAdditions)

+ (NSValue *)valueWithCLLocationCoordinate:(CLLocationCoordinate2D)coordinate
{
    return [NSValue valueWithBytes:(const void*)(&coordinate)
                          objCType:@encode(CLLocationCoordinate2D)];
}

- (CLLocationCoordinate2D)CLLocationCoordinateValue
{
    if (strcmp([self objCType], @encode(CLLocationCoordinate2D)) == 0)
    {
        CLLocationCoordinate2D coordinate;
        [self getValue:&coordinate];
        
        return coordinate;
    }
    
    return CLLocationCoordinate2DInvalid;
}

@end
