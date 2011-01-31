#import "CoreLocation+MITAdditions.h"
#import "MITProjection.h"

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
