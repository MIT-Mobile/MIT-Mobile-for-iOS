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
#import "MITShuttleStopPopoverViewController.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";
NSString * const kMITShuttleMapBusAnnotationViewReuseIdentifier = @"kMITShuttleMapBusAnnotationViewReuseIdentifier";

static const MKCoordinateRegion kMITShuttleDefaultMapRegion = {{42.357353, -71.095098}, {0.02, 0.02}};
static const CGFloat kMITShuttleMapRegionPaddingFactor = 0.1;

static const NSTimeInterval kMapExpandingAnimationDuration = 0.5;
static const NSTimeInterval kMapContractingAnimationDuration = 0.4;

static const NSTimeInterval kVehiclesRefreshInterval = 10.0;

static const CGFloat kMapAnnotationAlphaDefault = 1.0;
static const CGFloat kMapAnnotationAlphaTransparent = 0.5;

typedef NS_OPTIONS(NSUInteger, MITShuttleStopState) {
    MITShuttleStopStateDefault  = 0,
    MITShuttleStopStateSelected = 1 << 0,
    MITShuttleStopStateNext     = 1 << 1,
};

@interface MITShuttleMapViewController () <MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, MITShuttleStopPopoverViewControllerDelegate>

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
@property (nonatomic, strong) NSArray *secondaryRouteSegmentPolylines;

@property (nonatomic) BOOL shouldAnimateBusUpdate;
@property (nonatomic) BOOL shouldRepositionPopover;
@property (nonatomic) BOOL shouldRepositionMapOnRotate;
@property (nonatomic) BOOL touchesActive;

@property (nonatomic, strong) UIPopoverController *stopPopoverController;

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
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self setState:self.state animated:NO];
    } else {
        self.exitMapStateButton.alpha = 0;
    }
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

#pragma mark - UIViewController Methods

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (self.shouldRepositionMapOnRotate) {
        [self setupMapBoundingBoxAnimated:YES];
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.touchesActive = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.touchesActive = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.touchesActive = NO;
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
        NSPredicate *predicate;
        if (self.secondaryRoute) {
            predicate = [NSPredicate predicateWithFormat:@"SELF = %@ OR SELF = %@", self.route, self.secondaryRoute];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"SELF = %@", self.route];
        }
        _routesFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleRoute" predicate:predicate];
    }
    return _routesFetchedResultsController;
}

- (NSFetchedResultsController *)stopsFetchedResultsController
{
    if (!_stopsFetchedResultsController) {
        NSPredicate *predicate;
        if (self.route) {
            NSMutableSet *stops = [[self.route.stops set] mutableCopy];
            if (self.secondaryRoute) {
                [stops unionSet:[self.secondaryRoute.stops set]];
            }
            predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", stops];
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
            NSMutableSet *vehicles = [[self.route.vehicles set] mutableCopy];
            if (self.secondaryRoute) {
                [vehicles unionSet:[self.secondaryRoute.vehicles set]];
            }
            predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", vehicles];
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
        } else if (anObject == self.stop) {
            // do nothing, otherwise popover will be dismissed
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
    self.shouldRepositionMapOnRotate = YES;
    [self setupMapBoundingBoxAnimated:YES];
    
    if (stop && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // wait until map region change animation completes
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentPopoverForStop:stop];
        });
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
    MITShuttleRoute *route = self.secondaryRoute ? self.secondaryRoute : self.route;
    if ([route.pathBoundingBox isKindOfClass:[NSArray class]] && [route.pathBoundingBox count] > 3) {
        region = [route mapRegionWithPaddingFactor:kMITShuttleMapRegionPaddingFactor];
    } else {
        // Center on the MIT Campus with custom map tiles
        region = kMITShuttleDefaultMapRegion;
    }
    
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    [self.mapView setRegion:region animated:animated];

    self.hasSetUpMapRect = YES;
}

- (CGRect)rectForAnnotationView:(MKAnnotationView *)annotationView inView:(UIView *)view
{
    CGPoint center = [self.mapView convertCoordinate:annotationView.annotation.coordinate toPointToView:self.mapView];
    CGSize size = annotationView.frame.size;
    CGRect mapViewRect = CGRectMake(center.x - size.width / 2, center.y - size.height / 2, size.width, size.height);
    return [self.mapView convertRect:mapViewRect toView:view];
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

#pragma mark - Overlays/Annotations

- (void)refreshAll
{
    [self refreshRoutes];
    [self refreshStops];
    [self refreshVehicles];
}

- (void)refreshRoutes
{
    [self refreshPrimaryRoute];
    [self refreshSecondaryRoute];
}

- (void)refreshPrimaryRoute
{
    if (self.route && ![self.route pathSegmentsAreValid]) {
        return;
    }
    
    [self.mapView removeOverlays:self.routeSegmentPolylines];
    
    self.routeSegmentPolylines = [self.route pathSegmentPolylines];
    if ([self.routeSegmentPolylines count] > 0) {
        [self.mapView addOverlays:self.routeSegmentPolylines];
    }
}

- (void)refreshSecondaryRoute
{
    if (self.secondaryRoute && ![self.secondaryRoute pathSegmentsAreValid]) {
        return;
    }
    
    [self.mapView removeOverlays:self.secondaryRouteSegmentPolylines];
    
    self.secondaryRouteSegmentPolylines = [self.secondaryRoute pathSegmentPolylines];
    if ([self.secondaryRouteSegmentPolylines count] > 0) {
        [self.mapView addOverlays:self.secondaryRouteSegmentPolylines];
    }
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

- (void)removeMapAnnotationsForClass:(Class)class
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:class] && annotation != self.stop) {
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
            annotationView.image = [self annotationViewImageForStop:stop];
        } completion:nil];
    }
}

- (UIImage *)annotationViewImageForStop:(MITShuttleStop *)stop
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

- (CGFloat)annotationViewAlphaForStop:(MITShuttleStop *)stop
{
    if (self.secondaryRoute && [self.route.stops containsObject:stop] && ![self.secondaryRoute.stops containsObject:stop]) {
        return kMapAnnotationAlphaTransparent;
    } else {
        return kMapAnnotationAlphaDefault;
    }
}

- (CGFloat)annotationViewAlphaForVehicle:(MITShuttleVehicle *)vehicle
{
    if (self.secondaryRoute && vehicle.route == self.route) {
        return kMapAnnotationAlphaTransparent;
    } else {
        return kMapAnnotationAlphaDefault;
    }
}

- (CGFloat)overlayAlphaForPolyline:(MKPolyline *)polyline
{
    if (self.secondaryRoute && [self.routeSegmentPolylines containsObject:polyline]) {
        return kMapAnnotationAlphaTransparent;
    } else {
        return kMapAnnotationAlphaDefault;
    }
}

#pragma mark - Bus Annotation Animations

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

#pragma mark - Stop Selection

- (void)presentPopoverForStop:(MITShuttleStop *)stop
{
    MITShuttleStopPopoverViewController *viewController = [[MITShuttleStopPopoverViewController alloc] initWithStop:stop route:self.route];
    viewController.delegate = self;
    
    UIPopoverController *stopPopoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
    stopPopoverController.backgroundColor = [UIColor whiteColor];
    stopPopoverController.delegate = self;
    
    MKAnnotationView *stopAnnotationView = [self.mapView viewForAnnotation:stop];
    [stopPopoverController presentPopoverFromRect:[self rectForAnnotationView:stopAnnotationView inView:self.view] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    self.stopPopoverController = stopPopoverController;
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
        annotationView.image = [self annotationViewImageForStop:stop];
        annotationView.alpha = [self annotationViewAlphaForStop:stop];
        return annotationView;
    } else if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
        MITShuttleVehicle *vehicle = (MITShuttleVehicle *)annotation;
        
        MITShuttleMapBusAnnotationView *annotationView = (MITShuttleMapBusAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapBusAnnotationViewReuseIdentifier];
        if (!annotationView) {
            annotationView = [[MITShuttleMapBusAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITShuttleMapBusAnnotationViewReuseIdentifier];
        }
        annotationView.mapView = mapView;
        [annotationView setRouteTitle:vehicle.route.title];
        annotationView.alpha = [self annotationViewAlphaForVehicle:vehicle];
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
        self.stop = stop;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self presentPopoverForStop:stop];
        }
        
        if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
            [self.delegate shuttleMapViewController:self didSelectStop:stop];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    self.stop = nil;
    
    if (self.stopPopoverController.isPopoverVisible) {
        [self.stopPopoverController dismissPopoverAnimated:YES];
    }
    
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
        [self.delegate shuttleMapViewController:self didSelectStop:nil];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 2.5;
        renderer.fillColor = [UIColor blackColor];
        renderer.strokeColor = [UIColor blackColor];
        renderer.alpha = [self overlayAlphaForPolyline:overlay];
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
    if (self.stopPopoverController.isPopoverVisible) {
        self.shouldRepositionPopover = YES;
    }
    
    if (self.touchesActive) { // The user is touching and almost certainly manually repositioning the map
        self.shouldRepositionMapOnRotate = NO;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self startAnimatingBusAnnotations];
    if (self.shouldRepositionPopover) {
        MITShuttleStop *selectedStop = self.stop;
        MKAnnotationView *stopAnnotationView = [self.mapView viewForAnnotation:selectedStop];
        [self.stopPopoverController presentPopoverFromRect:[self rectForAnnotationView:stopAnnotationView inView:self.view] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
        self.shouldRepositionPopover = NO;
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (self.secondaryRoute) {
        self.secondaryRoute = nil;
        [self resetFetchedResults];
        [self setupMapBoundingBoxAnimated:YES];
    }
    [self.mapView deselectAnnotation:self.stop animated:YES];
    self.stop = nil;
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
        [self.delegate shuttleMapViewController:self didSelectStop:nil];
    }
}

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view
{
    MKAnnotationView *stopAnnotationView = [self.mapView viewForAnnotation:self.stop];
    *rect = [self rectForAnnotationView:stopAnnotationView inView:*view];
}

#pragma mark - MITShuttleStopPopoverViewControllerDelegate

- (void)stopPopoverViewController:(MITShuttleStopPopoverViewController *)viewController didScrollToRoute:(MITShuttleRoute *)route
{
    if (route == self.route) {
        self.secondaryRoute = nil;
    } else {
        self.secondaryRoute = route;
    }
    [self resetFetchedResults];
    [self setupMapBoundingBoxAnimated:YES];
}

- (void)stopPopoverViewController:(MITShuttleStopPopoverViewController *)viewController didSelectRoute:(MITShuttleRoute *)route
{
    self.route = route;
    self.secondaryRoute = nil;
    [self resetFetchedResults];
    [self setupMapBoundingBoxAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectRoute:)]) {
        [self.delegate shuttleMapViewController:self didSelectRoute:route];
    }
}

@end
