#import "MITLocationManager.h"

static const double kMilesPerMeter = 0.000621371;
static const int kDistanceFilterMeters = 100;

NSString * const kLocationManagerDidUpdateLocationNotification = @"kLocationManagerDidUpdateLocationNotification";
NSString * const kLocationManagerDidFailNotification = @"kLocationManagerDidFailNotification";
NSString * const kLocationManagerDidUpdateAuthorizationStatusNotification = @"kLocationManagerDidUpdateAuthorizationStatusNotification";

NSString * const kLocationManagerErrorKey = @"error";
NSString * const kLocationManagerAuthorizationStatusKey = @"authorizationStatus";

@interface MITLocationManager()

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MITLocationManager

+ (MITLocationManager *)sharedManager
{
    static MITLocationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupLocationManager];
    }
    return self;
}

#pragma mark - Setup

- (void)setupLocationManager
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kDistanceFilterMeters;
    
    self.locationManager = locationManager;
}

- (void)requestLocationAuthorization
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        [self.locationManager startUpdatingLocation];
        [self.locationManager stopUpdatingLocation];
    }
}

#pragma mark - Public Methods

- (void)startUpdatingLocation
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}

- (CLLocation *)currentLocation
{
    return self.locationManager.location;
}

- (double)milesFromCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocation *currentLocation = [self currentLocation];
    CLLocation *targetLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    return kMilesPerMeter * [currentLocation distanceFromLocation:targetLocation];
}

+ (BOOL)hasRequestedLocationPermissions
{
    return [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined;
}

+ (BOOL)locationServicesAuthorized
{
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateLocationNotification object:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidFailNotification object:nil userInfo:@{kLocationManagerErrorKey: error}];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil userInfo:@{kLocationManagerAuthorizationStatusKey: @(status)}];
}

@end
