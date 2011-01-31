#import <CoreLocation/CLLocation.h>

// these are 1 and 2 miles respectively
#define OUT_OF_BOUNDS_DISTANCE 1609
#define WAY_OUT_OF_BOUNDS_DISTANCE 3218

@interface CLLocation (MITAdditions)

- (CLLocationDistance)distanceFromCenterOfCampus;
- (BOOL)isOnCampus;
- (BOOL)isNearCampus;

@end
