//
//  MITLocationManager.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/15/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const kLocationManagerDidUpdateLocationNotification;
extern NSString * const kLocationManagerDidFailNotification;
extern NSString * const kLocationManagerDidFailErrorKey;

@interface MITLocationManager : NSObject <CLLocationManagerDelegate>

+ (MITLocationManager *)sharedManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (CLLocation *)currentLocation;
- (double)milesFromCoordinate:(CLLocationCoordinate2D)coordinate;

@end
