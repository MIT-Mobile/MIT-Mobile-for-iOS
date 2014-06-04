#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITShuttlePrediction.h"
#import "MITShuttleVehicle.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";

#pragma mark - MITShuttleMapAnnotation Class Definition

typedef enum {
    MITShuttleMapAnnotationTypeStop,
    MITShuttleMapAnnotationTypeNextStop,
    MITShuttleMapAnnotationTypeBus
} MITShuttleMapAnnotationType;

@interface MITShuttleMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) MITShuttleMapAnnotationType type;

@end

@implementation MITShuttleMapAnnotation

@end

@interface MITShuttleMapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *currentLocationButton;
@property (nonatomic, weak) IBOutlet UIButton *exitMapStateButton;
@property (nonatomic) BOOL hasSetUpMapRect;

- (IBAction)currentLocationButtonTapped:(id)sender;
- (IBAction)exitMapStateButtonTapped:(id)sender;

@end

@implementation MITShuttleMapViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _route = route;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.hasSetUpMapRect = NO;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    self.currentLocationButton.layer.borderWidth = 1;
    self.currentLocationButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.currentLocationButton.layer.cornerRadius = 4;
    self.currentLocationButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    
    self.exitMapStateButton.layer.borderWidth = 1;
    self.exitMapStateButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.exitMapStateButton.layer.cornerRadius = 4;
    self.exitMapStateButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    
    [self setState:self.state animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.hasSetUpMapRect) {
        CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(42.357353, -71.095098);
        
        MKMapPoint point = MKMapPointForCoordinate(centerCoordinate);
        [self.mapView setVisibleMapRect:MKMapRectMake(point.x, point.y, 10240.740226, 10240.740226) animated:NO];
        
        [self.mapView setCenterCoordinate:centerCoordinate];
        
        [self setupOverlays];
        [self refreshAnnotations];
        
        self.hasSetUpMapRect = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Accessors

- (void)setState:(MITShuttleMapState)state
{
    [self setState:state animated:YES];
}

- (void)setState:(MITShuttleMapState)state animated:(BOOL)animated
{
    _state = state;
    
    switch (state) {
        case MITShuttleMapStateContracted: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 0;
                self.exitMapStateButton.alpha = 0;
            };
            
            if (animated) {
                [UIView animateWithDuration:0.4 animations:animationBlock];
            } else {
                animationBlock();
            }
            
            break;
        }
        case MITShuttleMapStateExpanded: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 1;
                self.exitMapStateButton.alpha = 1;
            };
            
            if (animated) {
                [UIView animateWithDuration:0.5 animations:animationBlock];
            } else {
                animationBlock();
            }
            
            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)currentLocationButtonTapped:(id)sender
{
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
}

- (IBAction)exitMapStateButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewControllerExitFullscreenButtonPressed:)]) {
        [self.delegate shuttleMapViewControllerExitFullscreenButtonPressed:self];
    }
}

#pragma mark - Private Methods

- (void)setupOverlays
{
    [self setupTileOverlays];
    [self setupRouteOverlay];
}

- (void)setupRouteOverlay
{
    if (![self.route.pathSegments isKindOfClass:[NSArray class]]) {
        if (![self.route.pathSegments count] > 0 || ![self.route.pathSegments[0] isKindOfClass:[NSArray class]]) {
            return;
        }
    }
    
    NSArray *pathSegments = [self.route.pathSegments isKindOfClass:[NSArray class]] ? self.route.pathSegments : nil;
    
    NSMutableArray *segmentPolylines = [NSMutableArray array];
    
    if (pathSegments) {
        for (NSInteger i = 0; i < pathSegments.count; i++) {
            NSArray *pathSegment = [pathSegments[i] isKindOfClass:[NSArray class]] ? pathSegments[i] : nil;
            
            if (pathSegment) {
                CLLocationCoordinate2D segmentPoints[pathSegment.count];
                
                for (NSInteger j = 0; j < pathSegment.count; j++) {
                    NSArray *pathCoordinateArray = [pathSegment[j] isKindOfClass:[NSArray class]] ? pathSegment[j] : nil;
                    
                    if (pathCoordinateArray && pathCoordinateArray.count > 1) {
                        NSNumber *longitude = pathCoordinateArray[0];
                        NSNumber *latitude = pathCoordinateArray[1];
                        
                        CLLocationCoordinate2D pathPointCoordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
                        segmentPoints[j] = pathPointCoordinate;
                    }
                }
                
                MKPolyline *segmentPolyline = [MKPolyline polylineWithCoordinates:segmentPoints count:pathSegment.count];
                [segmentPolylines addObject:segmentPolyline];
            }
        }
    }
    
    // If we got nothing, its broken somehow so don't show anything
    if (segmentPolylines.count < 1) {
        return;
    }
    
    for (MKPolyline *polyline in segmentPolylines) {
        [self.mapView addOverlay:polyline];
    }
}

- (void)setupTileOverlays
{
    [self setupBaseTileOverlay];
    [self setupMITTileOverlay];
}

- (void)setupMITTileOverlay
{
    static NSString * const template = @"http://m.mit.edu/api/arcgis/WhereIs_Base_Topo/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *MITTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    MITTileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:MITTileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)setupBaseTileOverlay
{
    static NSString * const template = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *baseTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    baseTileOverlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:baseTileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)refreshAnnotations {
    NSMutableArray *newAnnotations = [NSMutableArray array];
    
    NSMutableArray *nextStops = [NSMutableArray array];
    for (MITShuttleVehicle *vehicle in self.route.vehicles) {
        NSNumber *leastSecondsRemaining = nil;
        MITShuttleStop *nextStop = nil;
        
        for (MITShuttleStop *stop in self.route.stops) {
            for (MITShuttlePrediction *prediction in stop.predictions) {
                if ([prediction.vehicleId isEqualToString:vehicle.identifier]) {
                    if (nextStop == nil || [leastSecondsRemaining compare:prediction.seconds] == NSOrderedDescending) {
                        leastSecondsRemaining = prediction.seconds;
                        nextStop = stop;
                    }
                }
            }
        }
        
        if (nextStop != nil) {
            [nextStops addObject:nextStop];
        }
    }
    
    for (MITShuttleStop *stop in self.route.stops) {
        MITShuttleMapAnnotation *annotation = [[MITShuttleMapAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake([stop.latitude doubleValue], [stop.longitude doubleValue]);
        
        annotation.type = MITShuttleMapAnnotationTypeStop;
        for (MITShuttleStop *nextStop in nextStops) {
            if ([nextStop.identifier isEqualToString:stop.identifier]) {
                annotation.type = MITShuttleMapAnnotationTypeNextStop;
            }
        }
        
        [newAnnotations addObject:annotation];
    }
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:newAnnotations];
}

#pragma mark - MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MITShuttleMapAnnotation *typedAnnotation = (MITShuttleMapAnnotation *)annotation;
    
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:typedAnnotation reuseIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
    }
    
    switch (typedAnnotation.type) {
        case MITShuttleMapAnnotationTypeStop: {
            annotationView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot"];
            break;
        }
        case MITShuttleMapAnnotationTypeNextStop: {
            annotationView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next"];
            break;
        }
        case MITShuttleMapAnnotationTypeBus: {
            annotationView.image = [UIImage imageNamed:@"shuttle/shuttle"];
            break;
        }
    }
    
    return annotationView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 2.5;
        renderer.fillColor = [UIColor darkGrayColor];
        renderer.strokeColor = [UIColor darkGrayColor];
        
        return renderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    } else {
        return nil;
    }
}

@end
