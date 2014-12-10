#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const kLocationManagerDidUpdateLocationNotification;
extern NSString * const kLocationManagerDidFailNotification;
extern NSString * const kLocationManagerDidUpdateAuthorizationStatusNotification;

extern NSString * const kLocationManagerErrorKey;
extern NSString * const kLocationManagerAuthorizationStatusKey;

@interface MITLocationManager : NSObject <CLLocationManagerDelegate>

+ (MITLocationManager *)sharedManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (CLLocation *)currentLocation;
- (double)milesFromCoordinate:(CLLocationCoordinate2D)coordinate;

+ (BOOL)hasRequestedLocationPermissions;
+ (BOOL)locationServicesAuthorized;

@end
