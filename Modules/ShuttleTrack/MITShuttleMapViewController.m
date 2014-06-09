#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute+MapKit.h"
#import "MITShuttleStop.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITShuttlePrediction.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleMapBusAnnotationView.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";
NSString * const kMITShuttleMapBusAnnotationViewReuseIdentifier = @"kMITShuttleMapBusAnnotationViewReuseIdentifier";

static const CLLocationCoordinate2D kMITShuttleDefaultMapCenter = {42.357353, -71.095098};
static const CLLocationDistance kMITShuttleDefaultMapSpan = 10240.740226;
static const CGFloat kMITShuttleMapRegionPaddingFactor = 0.1;

static const NSTimeInterval kMapExpandingAnimationDuration = 0.5;
static const NSTimeInterval kMapContractingAnimationDuration = 0.4;

typedef enum {
    MITShuttleMapAnnotationTypeStop,
    MITShuttleMapAnnotationTypeNextStop,
} MITShuttleMapAnnotationType;

#pragma mark - MITShuttleMapAnnotation Class

@interface MITShuttleMapStopAnnotation : NSObject <MKAnnotation>

@property (nonatomic) MITShuttleMapAnnotationType type;
@property (nonatomic, strong) MITShuttleStop *stop;

@end

@implementation MITShuttleMapStopAnnotation

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.stop.latitude doubleValue], [self.stop.longitude doubleValue]);
}

@end

#pragma mark - MITShuttleMapBusAnnotation Class

@interface MITShuttleMapBusAnnotation : NSObject <MKAnnotation>

@property (nonatomic) MITShuttleMapAnnotationType type;
@property (nonatomic, strong) MITShuttleVehicle *vehicle;

@end

@implementation MITShuttleMapBusAnnotation

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.vehicle.latitude doubleValue], [self.vehicle.longitude doubleValue]);
}

@end

#pragma mark - MITShuttleMapViewController Class

@interface MITShuttleMapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *currentLocationButton;
@property (nonatomic, weak) IBOutlet UIButton *exitMapStateButton;
@property (nonatomic) BOOL hasSetUpMapRect;
@property (nonatomic, strong) NSArray *busAnnotations;
@property (nonatomic, strong) NSDictionary *busAnnotationViewsByVehicleId;
@property (nonatomic, strong) NSArray *stopAnnotations;
@property (nonatomic) BOOL shouldAnimateBusUpdate;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.hasSetUpMapRect) {
        [self setupMapBoundingBoxAnimated:NO];
    }
    
    [self setupOverlays];
    [self createStopsAnnotations];
    [self refreshBusAnnotationsAnimated:NO];
    
    self.shouldAnimateBusUpdate = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // This seems to prevent a crash with a VKRasterOverlayTileSource being deallocated and sent messages
    [self.mapView removeOverlays:self.mapView.overlays];
    
    [super viewWillDisappear:animated];
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
        case MITShuttleMapStateContracting: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 0;
                self.exitMapStateButton.alpha = 0;
            };
            
            if (animated) {
                [UIView animateWithDuration:kMapContractingAnimationDuration animations:animationBlock];
            } else {
                animationBlock();
            }
            
            self.mapView.scrollEnabled = NO;
            self.mapView.zoomEnabled = NO;
            
            break;
        }
        case MITShuttleMapStateExpanding: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 1;
                self.exitMapStateButton.alpha = 1;
            };
            
            if (animated) {
                [UIView animateWithDuration:kMapExpandingAnimationDuration animations:animationBlock];
            } else {
                animationBlock();
            }
            
            self.mapView.scrollEnabled = YES;
            self.mapView.zoomEnabled = YES;
            
            break;
        }
            
        case MITShuttleMapStateContracted: {
            [self setupMapBoundingBoxAnimated:animated];
            break;
        }
        case MITShuttleMapStateExpanded: {
            // Noop
            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)currentLocationButtonTapped:(id)sender
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Turn on Location Services to Allow Shuttles to Determine Your Location." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (IBAction)exitMapStateButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewControllerExitFullscreenButtonPressed:)]) {
        [self.delegate shuttleMapViewControllerExitFullscreenButtonPressed:self];
    }
}

#pragma mark - Public Methods

- (void)routeUpdated
{
    [self refreshAnnotationsAnimated:YES];
}

#pragma mark - Private Methods

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    if ([self.route.pathBoundingBox isKindOfClass:[NSArray class]] && [self.route.pathBoundingBox count] > 3) {
        MKCoordinateRegion boundingBox = [self.route mapRegionWithPaddingFactor:kMITShuttleMapRegionPaddingFactor];
        [self.mapView setRegion:boundingBox animated:animated];
    } else {
        // Center on the MIT Campus with custom map tiles
        CLLocationCoordinate2D centerCoordinate = kMITShuttleDefaultMapCenter;
        MKMapPoint point = MKMapPointForCoordinate(centerCoordinate);
        
        [self.mapView setVisibleMapRect:MKMapRectMake(point.x, point.y, kMITShuttleDefaultMapSpan, kMITShuttleDefaultMapSpan) animated:animated];
        [self.mapView setCenterCoordinate:centerCoordinate];
    }
    
    self.hasSetUpMapRect = YES;
}

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

- (void)refreshBusAnnotationsAnimated:(BOOL)animated
{
    NSMutableArray *newBusAnnotations = [NSMutableArray array];
    
    NSMutableArray *annotationsToUpdate = [NSMutableArray array];
    NSMutableArray *annotationsToAdd = [NSMutableArray array];
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    
    for (MITShuttleVehicle *vehicle in self.route.vehicles) {
        NSUInteger indexOfAnnotationForThisVehicle = [self.busAnnotations indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            MITShuttleMapBusAnnotation *annotation = obj;
            if ([annotation.vehicle.identifier isEqualToString:vehicle.identifier]) {
                return YES;
            } else {
                return NO;
            }
        }];
        
        if (indexOfAnnotationForThisVehicle == NSNotFound || self.busAnnotations == nil) {
            MITShuttleMapBusAnnotation *annotation = [[MITShuttleMapBusAnnotation alloc] init];
            annotation.vehicle = vehicle;
            [annotationsToAdd addObject:annotation];
        } else {
            [annotationsToUpdate addObject:self.busAnnotations[indexOfAnnotationForThisVehicle]];
        }
    }
    
    for (MITShuttleMapBusAnnotation *annotation in self.busAnnotations) {
        NSUInteger indexOfVehicleForThisAnnotation = [self.route.vehicles indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            MITShuttleVehicle *vehicle = obj;
            if ([annotation.vehicle.identifier isEqualToString:vehicle.identifier]) {
                return YES;
            } else {
                return NO;
            }
        }];
        
        if (indexOfVehicleForThisAnnotation == NSNotFound) {
            [annotationsToRemove addObject:annotation];
        }
    }
    
    NSMutableDictionary *newBusAnnotationViewsByVehicleId = [NSMutableDictionary dictionaryWithDictionary:self.busAnnotationViewsByVehicleId];
    
    for (MITShuttleMapBusAnnotation *annotation in annotationsToRemove) {
        [newBusAnnotationViewsByVehicleId removeObjectForKey:annotation.vehicle.identifier];
    }
    
    for (MITShuttleMapBusAnnotation *annotation in annotationsToAdd) {
        MITShuttleMapBusAnnotationView *newAnnotationView = [[MITShuttleMapBusAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"none"];
        newAnnotationView.mapView = self.mapView;
        newAnnotationView.image = [UIImage imageNamed:@"shuttle/shuttle"];
        [newBusAnnotationViewsByVehicleId setObject:newAnnotationView forKey:annotation.vehicle.identifier];
    }
    
    self.busAnnotationViewsByVehicleId = [NSDictionary dictionaryWithDictionary:newBusAnnotationViewsByVehicleId];
    
    for (MITShuttleMapBusAnnotation *annotation in annotationsToUpdate) {
        MITShuttleMapBusAnnotationView *annotationView = self.busAnnotationViewsByVehicleId[annotation.vehicle.identifier];
        [annotationView updateVehicle:annotation.vehicle animated:animated];
    }
    
    [self.mapView removeAnnotations:annotationsToRemove];
    [self.mapView addAnnotations:annotationsToAdd];
    
    [newBusAnnotations addObjectsFromArray:annotationsToUpdate];
    [newBusAnnotations addObjectsFromArray:annotationsToAdd];
    self.busAnnotations = [NSArray arrayWithArray:newBusAnnotations];
}

- (void)refreshNextStopAnnotations
{
    for (MITShuttleMapStopAnnotation *annotation in self.stopAnnotations) {
        NSUInteger indexOfNextStopForThisAnnotation = [[self nextStopsArray] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            MITShuttleStop *shuttleStop = obj;
            if ([annotation.stop.identifier isEqualToString:shuttleStop.identifier]) {
                return YES;
            } else {
                return NO;
            }
        }];
        
        if (indexOfNextStopForThisAnnotation == NSNotFound && annotation.type != MITShuttleMapAnnotationTypeStop) {
            annotation.type = MITShuttleMapAnnotationTypeStop;
            [self.mapView removeAnnotation:annotation];
            [self.mapView addAnnotation:annotation];
        } else if (indexOfNextStopForThisAnnotation != NSNotFound && annotation.type != MITShuttleMapAnnotationTypeNextStop) {
            annotation.type = MITShuttleMapAnnotationTypeNextStop;
            [self.mapView removeAnnotation:annotation];
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (NSArray *)nextStopsArray
{
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
    
    return nextStops;
}

- (void)createStopsAnnotations
{
    NSMutableArray *newStopAnnotations = [NSMutableArray array];
    
    for (MITShuttleStop *stop in self.route.stops) {
        MITShuttleMapStopAnnotation *annotation = [[MITShuttleMapStopAnnotation alloc] init];
        annotation.stop = stop;
        annotation.type = MITShuttleMapAnnotationTypeStop;
        for (MITShuttleStop *nextStop in [self nextStopsArray]) {
            if ([nextStop.identifier isEqualToString:stop.identifier]) {
                annotation.type = MITShuttleMapAnnotationTypeNextStop;
            }
        }
        
        [newStopAnnotations addObject:annotation];
    }
    
    [self.mapView removeAnnotations:self.stopAnnotations];
    self.stopAnnotations = [NSArray arrayWithArray:newStopAnnotations];
    [self.mapView addAnnotations:self.stopAnnotations];
}

- (void)refreshAnnotationsAnimated:(BOOL)animated
{
    BOOL shouldAnimatedBusAnnotations = animated && self.shouldAnimateBusUpdate;
    [self refreshBusAnnotationsAnimated:shouldAnimatedBusAnnotations];
    [self refreshNextStopAnnotations];
    self.shouldAnimateBusUpdate = YES;
}

- (UIImage *)imageForAnnotationType:(MITShuttleMapAnnotationType)type
{
    switch (type) {
        case MITShuttleMapAnnotationTypeStop: {
            return [UIImage imageNamed:@"shuttle/shuttle-stop-dot"];
            break;
        }
        case MITShuttleMapAnnotationTypeNextStop: {
            return [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next"];
            break;
        }
    }
}

#pragma mark - MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else if ([annotation isKindOfClass:[MITShuttleMapStopAnnotation class]]) {
        MITShuttleMapStopAnnotation *typedAnnotation = (MITShuttleMapStopAnnotation *)annotation;
        
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:typedAnnotation reuseIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        }
        
        annotationView.image = [self imageForAnnotationType:typedAnnotation.type];
        
        return annotationView;
    } else if ([annotation isKindOfClass:[MITShuttleMapBusAnnotation class]]) {
        MITShuttleMapBusAnnotation *typedAnnotation = (MITShuttleMapBusAnnotation *)annotation;
        MITShuttleMapBusAnnotationView *annotationView = self.busAnnotationViewsByVehicleId[typedAnnotation.vehicle.identifier];
        
        return annotationView;
    }
    
    return nil;
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
