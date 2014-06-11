#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute+MapKit.h"
#import "MITShuttleStop.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITShuttlePrediction.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleMapBusAnnotationView.h"
#import "MITCoreDataController.h"
#import "MITShuttleController.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";
NSString * const kMITShuttleMapBusAnnotationViewReuseIdentifier = @"kMITShuttleMapBusAnnotationViewReuseIdentifier";

static const MKCoordinateRegion kMITShuttleDefaultMapRegion = {{42.357353, -71.095098}, {0.01, 0.01}};
static const CGFloat kMITShuttleMapRegionPaddingFactor = 0.1;

static const NSTimeInterval kMapExpandingAnimationDuration = 0.5;
static const NSTimeInterval kMapContractingAnimationDuration = 0.4;

static const NSTimeInterval kVehiclesRefreshInterval = 10.0;

typedef NS_OPTIONS(NSUInteger, MITShuttleStopState) {
    MITShuttleStopStateDefault  = 0,
    MITShuttleStopStateSelected = 1 << 0,
    MITShuttleStopStateNext     = 1 << 1,
};

@interface MITShuttleMapViewController () <MKMapViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *currentLocationButton;
@property (nonatomic, weak) IBOutlet UIButton *exitMapStateButton;

@property (nonatomic, strong) NSFetchedResultsController *routesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *stopsFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *vehiclesFetchedResultsController;

@property (nonatomic, readonly) NSArray *routes;
@property (nonatomic, readonly) NSArray *stops;
@property (nonatomic, readonly) NSArray *vehicles;

@property (nonatomic, strong) NSTimer *vehiclesRefreshTimer;
@property (nonatomic) BOOL hasSetUpMapRect;
@property (nonatomic, strong) NSArray *routeSegmentPolylines;
@property (nonatomic, strong) NSArray *busAnnotations;
@property (nonatomic, strong) NSDictionary *busAnnotationViewsByVehicleId;
@property (nonatomic, strong) NSArray *stopAnnotations;
@property (nonatomic) BOOL shouldAnimateBusUpdate;

- (IBAction)currentLocationButtonTapped:(id)sender;
- (IBAction)exitMapStateButtonTapped:(id)sender;

@end

@implementation MITShuttleMapViewController

#pragma mark - Init

- (instancetype)initWithRoute:(MITShuttleRoute *)route
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _route = route;
    }
    return self;
}

#pragma mark - View Lifecycle

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
    [self prepareForViewAppearance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self prepareForViewDisappearance];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [super viewWillDisappear:animated];
}

- (void)prepareForViewAppearance
{
    if (!self.hasSetUpMapRect) {
        [self setupMapBoundingBoxAnimated:NO];
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self startRefreshingVehicles];
    }

    [self setupTileOverlays];
    self.shouldAnimateBusUpdate = NO;
    [self performFetch];
}

- (void)prepareForViewDisappearance
{
    // This seems to prevent a crash with a VKRasterOverlayTileSource being deallocated and sent messages
    [self.mapView removeOverlays:self.mapView.overlays];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self stopRefreshingVehicles];
    }
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self prepareForViewAppearance];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self prepareForViewDisappearance];
}

#pragma mark - Vehicles Refresh Timer

- (void)startRefreshingVehicles
{
    [self loadVehicles];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vehiclesRefreshTimer invalidate];
        NSTimer *vehiclesRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kVehiclesRefreshInterval
                                                                      target:self
                                                                    selector:@selector(loadVehicles)
                                                                    userInfo:nil
                                                                     repeats:YES];
        self.vehiclesRefreshTimer = vehiclesRefreshTimer;
    });
}

- (void)stopRefreshingVehicles
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vehiclesRefreshTimer invalidate];
        self.vehiclesRefreshTimer = nil;
    });
}

#pragma mark - Load Route

- (void)loadVehicles
{
    [[MITShuttleController sharedController] getVehicles:^(NSArray *vehicles, NSError *error) {
        self.shouldAnimateBusUpdate = YES;
    }];
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

- (void)setStop:(MITShuttleStop *)stop
{
    _stop = stop;
    [self refreshStopAnnotationImages];
}

- (NSArray *)routes
{
    return [self.routesFetchedResultsController fetchedObjects];
}

- (NSArray *)stops
{
    return [self.stopsFetchedResultsController fetchedObjects];
}

- (NSArray *)vehicles
{
    return [self.vehiclesFetchedResultsController fetchedObjects];
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

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)routesFetchedResultsController
{
    if (!_routesFetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF = %@", self.route];
        _routesFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleRoute" predicate:predicate];
    }
    return _routesFetchedResultsController;
}

- (NSFetchedResultsController *)stopsFetchedResultsController
{
    if (!_stopsFetchedResultsController) {
        NSPredicate *predicate;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", self.route.stops];
        }
        _stopsFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleStop" predicate:predicate];
    }
    return _stopsFetchedResultsController;
}

- (NSFetchedResultsController *)vehiclesFetchedResultsController
{
    if (!_vehiclesFetchedResultsController) {
        NSPredicate *predicate;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", self.route.vehicles];
        }
        _vehiclesFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleVehicle" predicate:predicate];
    }
    return _vehiclesFetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntityWithName:(NSString *)entityName predicate:(NSPredicate *)predicate
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:predicate];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    fetchedResultsController.delegate = self;
    return fetchedResultsController;
}

- (void)resetFetchedResults
{
    self.routesFetchedResultsController = nil;
    self.stopsFetchedResultsController = nil;
    self.vehiclesFetchedResultsController = nil;
    
    [self performFetch];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self addObject:anObject];
            break;
        case NSFetchedResultsChangeDelete:
            [self removeObject:anObject];
            break;
        case NSFetchedResultsChangeUpdate:
            [self updateObject:anObject];
            break;
        default:
            break;
    }
}

- (void)addObject:(id)anObject
{
    if ([anObject conformsToProtocol:@protocol(MKAnnotation)]) {
        [self.mapView addAnnotation:anObject];
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoutes];
    }
}

- (void)removeObject:(id)anObject
{
    if ([anObject conformsToProtocol:@protocol(MKAnnotation)]) {
        [self.mapView removeAnnotation:anObject];
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoutes];
    }
}

- (void)updateObject:(id)anObject
{
    if ([anObject conformsToProtocol:@protocol(MKAnnotation)]) {
        if ([anObject isKindOfClass:[MITShuttleVehicle class]]) {
            if (self.shouldAnimateBusUpdate) {
                [anObject setCoordinate:((MITShuttleVehicle *)anObject).coordinate];
            } else {
                if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                    self.shouldAnimateBusUpdate = YES;
                }
                [self removeObject:anObject];
                [self addObject:anObject];
            }
        } else {
            [self removeObject:anObject];
            [self addObject:anObject];
        }
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoutes];
    }
}

#pragma mark - Public Methods

- (void)setRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    self.route = route;
    self.stop = stop;
    [self resetFetchedResults];
    [self setupMapBoundingBoxAnimated:YES];
    
    if (stop && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // TODO: present popover for stop
    }
}

- (void)routeUpdated
{
    [self refreshStopAnnotationImages];
}

#pragma mark - Private Methods

- (void)performFetch
{
    [self.routesFetchedResultsController performFetch:nil];
    [self.stopsFetchedResultsController performFetch:nil];
    [self.vehiclesFetchedResultsController performFetch:nil];
    [self refreshAll];
}

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    MKCoordinateRegion region;
    if ([self.route.pathBoundingBox isKindOfClass:[NSArray class]] && [self.route.pathBoundingBox count] > 3) {
        region = [self.route mapRegionWithPaddingFactor:kMITShuttleMapRegionPaddingFactor];
    } else {
        // Center on the MIT Campus with custom map tiles
        region = kMITShuttleDefaultMapRegion;
    }
    [self.mapView setRegion:region animated:animated];

    self.hasSetUpMapRect = YES;
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

#pragma mark - Route Overlay

- (void)refreshAll
{
    [self refreshRoutes];
    [self refreshStops];
    [self refreshVehicles];
}

- (void)refreshRoutes
{
    if (self.route && ![self.route.pathSegments isKindOfClass:[NSArray class]]) {
        if (![self.route.pathSegments count] > 0 || ![self.route.pathSegments[0] isKindOfClass:[NSArray class]]) {
            return;
        }
    }
    
    [self.mapView removeOverlays:self.routeSegmentPolylines];
    
    NSArray *pathSegments = [self.route.pathSegments isKindOfClass:[NSArray class]] ? self.route.pathSegments : nil;
    
    NSMutableArray *segmentPolylines = [NSMutableArray arrayWithCapacity:[pathSegments count]];
    
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
    
    [self.mapView addOverlays:segmentPolylines];
    
    self.routeSegmentPolylines = [NSArray arrayWithArray:segmentPolylines];
}

- (void)refreshStops
{
    [self removeMapAnnotationsForClass:[MITShuttleStop class]];
    for (MITShuttleStop *stop in self.stops) {
        [self addObject:stop];
    }
}

- (void)refreshVehicles
{
    [self removeMapAnnotationsForClass:[MITShuttleVehicle class]];
    for (MITShuttleVehicle *vehicle in self.vehicles) {
        [self addObject:vehicle];
    }
}

- (void)startAnimatingBusAnnotations
{
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
            [(MITShuttleMapBusAnnotationView *)[self.mapView viewForAnnotation:annotation] startAnimating];
        }
    }
}

- (void)stopAnimatingBusAnnotations
{
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
            [(MITShuttleMapBusAnnotationView *)[self.mapView viewForAnnotation:annotation] stopAnimating];
        }
    }
}

- (void)removeMapAnnotationsForClass:(Class)class
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:class]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}

- (void)refreshStopAnnotationImages
{
    for (MITShuttleStop *stop in self.stops) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:stop];
        [UIView transitionWithView:annotationView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            annotationView.image = [self stopAnnotationImageForStop:stop];
        } completion:nil];
    }
}

- (UIImage *)stopAnnotationImageForStop:(MITShuttleStop *)stop
{
    MITShuttleStopState state = MITShuttleStopStateDefault;
    if ([self.route.nextStops containsObject:stop]) {
        state = state | MITShuttleStopStateNext;
    }
    if (self.stop == stop) {
        state = state | MITShuttleStopStateSelected;
    }

    if (state == MITShuttleStopStateDefault) {
        return [UIImage imageNamed:@"shuttle/shuttle-stop-dot"];
    } else if (state == MITShuttleStopStateNext) {
        return [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next"];
    } else if (state == MITShuttleStopStateSelected) {
        return [UIImage imageNamed:@"shuttle/shuttle-stop-dot-selected"] ;
    } else if (state == (MITShuttleStopStateNext | MITShuttleStopStateSelected)) {
        return [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next-selected"];
    }
    return nil;
}

#pragma mark - MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else if ([annotation isKindOfClass:[MITShuttleStop class]]) {
        MITShuttleStop *stop = (MITShuttleStop *)annotation;
        
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        }
        annotationView.image = [self stopAnnotationImageForStop:stop];
        return annotationView;
    } else if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
        MITShuttleMapBusAnnotationView *annotationView = (MITShuttleMapBusAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapBusAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[MITShuttleMapBusAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITShuttleMapBusAnnotationViewReuseIdentifier];
        }
        [(MITShuttleMapBusAnnotationView *)annotationView setMapView:mapView];
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[MITShuttleVehicle class]]) {
            [view.superview bringSubviewToFront:view];
        } else {
            [view.superview sendSubviewToBack:view];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    id<MKAnnotation> annotation = view.annotation;
    if ([annotation isKindOfClass:[MITShuttleStop class]]) {
        MITShuttleStop *stop = (MITShuttleStop *)annotation;
        // TODO: show popover from stop annotation
        if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
            [self.delegate shuttleMapViewController:self didSelectStop:stop];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
        [self.delegate shuttleMapViewController:self didSelectStop:nil];
    }
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

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [self stopAnimatingBusAnnotations];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self startAnimatingBusAnnotations];
}

@end
