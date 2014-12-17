#import "MITTiledMapView.h"
#import "MITMapDelegateInterceptor.h"
#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITLocationManager.h"
#import "UIKit+MITAdditions.h"
#import "MITTileOverlay.h"

const MKCoordinateRegion kMITShuttleDefaultMapRegion = {{42.357353, -71.095098}, {0.02, 0.02}};
const MKCoordinateRegion kMITToursDefaultMapRegion = {{42.359979, -71.091860}, {0.0053103, 0.0123639}};

@interface MITTiledMapView() <UIAlertViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *userLocationButton;

@property (nonatomic, strong) MITMapDelegateInterceptor *delegateInterceptor;

@end

@implementation MITTiledMapView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Private Methods

- (void)setup
{
    [self setupMapView];
    [self setupTileOverlays];
    
    [self setMapDelegate:nil]; // Ensures that we're at least intercepting delegate calls we want to, even if the user never sets a proper delegate
}

- (MITCalloutMapView *)createMapView
{
    return [[MITCalloutMapView alloc] initWithFrame:self.frame];
}

- (void)setupMapView
{
    self.mapView = [self createMapView];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.mapView];
    
    NSDictionary *viewDictionary = @{@"mapView": self.mapView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapView]|" options:0 metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapView]|" options:0 metrics:nil views:viewDictionary]];
    
    self.mapView.tintColor = [UIColor mit_systemTintColor];
}

#pragma mark - Public Methods

- (BOOL)isTrackingUser
{
    return self.mapView.userTrackingMode == MKUserTrackingModeFollow || self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading;
}

- (void)showLocationServicesAlert
{
    NSString *alertMessage = @"Turn on Location Services to Allow \"MIT Mobile\" to Determine Your Location";
    UIAlertView *alert;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        alert = [[UIAlertView alloc] initWithTitle:alertMessage message:nil delegate:self cancelButtonTitle:@"Settings" otherButtonTitles:@"Cancel", nil];
    }
    else {
        alert = [[UIAlertView alloc] initWithTitle:alertMessage message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];

    }
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
#ifdef __IPHONE_8_0 // This allows us to compile with XCode 5/iOS 7 SDK
        if ((&UIApplicationOpenSettingsURLString != NULL)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
#endif
    }
}

#pragma mark - Buttons

- (UIBarButtonItem *)userLocationButton
{
    if (!_userLocationButton) {
        _userLocationButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    }
    
    return _userLocationButton;
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        [[MITLocationManager sharedManager] requestLocationAuthorization];
    }
    else if (status == kCLAuthorizationStatusDenied) {
        [self showLocationServicesAlert];
    }
}

#pragma mark - Route drawing

- (void)showRouteForStops:(NSArray *)stops
{
    for (MITToursStop *stop in stops) {
        MITToursDirectionsToStop *directionsToNextStop = stop.directionsToNextStop;
        NSArray *routePoints = (NSArray *)directionsToNextStop.path;
        CLLocationCoordinate2D segmentPoints[routePoints.count];
        for (NSInteger i = 0; i < routePoints.count; i++) {
            NSArray *point = [routePoints objectAtIndex:i];
            // Convert to location coordinate
            NSNumber *longitude = [point objectAtIndex:0];
            NSNumber *latitude = [point objectAtIndex:1];
            segmentPoints[i] = CLLocationCoordinate2DMake([latitude doubleValue],[longitude doubleValue]);
        }
        MKPolyline *polyline = [MKPolyline polylineWithCoordinates:segmentPoints count:routePoints.count];
        [self.mapView addOverlay:polyline];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 4.0;
        renderer.fillColor = [UIColor colorWithRed:0.0 green:140.0/255.0 blue:255.0/255.0 alpha:0.80];
        renderer.strokeColor = [UIColor colorWithRed:0.0 green:140.0/255.0 blue:255.0/255.0 alpha:0.80];
        renderer.alpha = 1.0;
        return renderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    } else {
        return nil;
    }
}

- (void)zoomToFitCoordinates:(NSArray *)coordinates
{
    // Longitude ranges from -180 to 180...
    CLLocationDegrees minLongitude = 181;
    CLLocationDegrees maxLongitude = -181;
    
    // Lattitude ranges from -90 to 90...
    CLLocationDegrees minLattitude = 91;
    CLLocationDegrees maxLattitude = -91;
    
    for (NSArray *coordinateArray in coordinates) {
        if (coordinateArray.count < 2) {
            return;
        }
        CLLocationDegrees longitude = [coordinateArray[0] doubleValue];
        CLLocationDegrees lattitude = [coordinateArray[1] doubleValue];
    
        if (longitude > maxLongitude) {
            maxLongitude = longitude;
        }
        if (longitude < minLongitude) {
            minLongitude = longitude;
        }
        
        if (lattitude > maxLattitude) {
            maxLattitude = lattitude;
        }
        if (lattitude < minLattitude) {
            minLattitude = lattitude;
        }
    }
    
    if (minLongitude > 180 || maxLongitude < -181 ||
        maxLattitude > 90 || maxLattitude < -90) {
        return;
    }
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake((maxLattitude + minLattitude) / 2, (maxLongitude + minLongitude) / 2);
    CLLocationDegrees padding = 0.0005;
    MKCoordinateSpan span = MKCoordinateSpanMake(maxLattitude - minLattitude + padding, maxLongitude - minLongitude + padding);
        
    [self.mapView setRegion:MKCoordinateRegionMake(center, span) animated:NO];
}

#pragma mark - Tile Overlays

- (void)setupTileOverlays
{
    [self setupBaseTileOverlay];
    [self setupMITTileOverlay];
}

- (void)setupMITTileOverlay
{
    static NSString * const template = @"http://m.mit.edu/api/arcgis/WhereIs_Base_Topo/MapServer/tile/{z}/{y}/{x}";
    
    MITTileOverlay *tileOverlay = [[MITTileOverlay alloc] initWithURLTemplate:template];
    tileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)setupBaseTileOverlay
{
    static NSString * const template = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *baseTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    baseTileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:baseTileOverlay level:MKOverlayLevelAboveLabels];
}

#pragma mark - Map View Delegate


- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    [self.userTrackingDelegate mitTiledMapView:self didChangeUserTrackingMode:mode animated:animated];
}

- (void)setMapDelegate:(id<MKMapViewDelegate>)mapDelegate
{
    self.delegateInterceptor.middleManDelegate = self;
    self.delegateInterceptor.endOfLineDelegate = mapDelegate;
    
    // Have to set the delegate to something else and then back, because MKMapView only checks the delegate methods its delegate responds to once, at the time of setting
    // Since we could be changing which selectors the interceptor responds to here, we have to force MKMapView to re-query it
    self.mapView.delegate = nil;
    self.mapView.delegate = self.delegateInterceptor;
}

- (MITMapDelegateInterceptor *)delegateInterceptor
{
    if (!_delegateInterceptor) {
        _delegateInterceptor = [[MITMapDelegateInterceptor alloc] init];

    }
    return _delegateInterceptor;
}

@end
