#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CoreLocation.h>

#define DEGREES_PER_RADIAN 180.0 / M_PI
#define RADIANS_PER_DEGREE M_PI / 180.0

#define DEFAULT_MAP_CENTER CLLocationCoordinate2DMake(42.35913,-71.09325)
#define DEFAULT_MAP_SPAN MKCoordinateSpanMake(0.006, 0.006)

// these are 1 and 2 miles respectively
#define OUT_OF_BOUNDS_DISTANCE 1609
#define WAY_OUT_OF_BOUNDS_DISTANCE 3218

FOUNDATION_STATIC_INLINE inline NSString* NSStringFromCLLocationCoordinate2D(CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"{ x: %lf, y: %lf }", coordinate.longitude, coordinate.latitude];
}

@interface CLLocation (MITAdditions)

- (CLLocationDistance)distanceFromCenterOfCampus;
- (BOOL)isOnCampus;
- (BOOL)isNearCampus;

@end

@interface NSValue (CL_MITAdditions)
+ (NSValue *)valueWithMKCoordinate:(CLLocationCoordinate2D)coordinate;
- (CLLocationCoordinate2D)MKCoordinateValue;

@end