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
#import "UIKit+MITAdditions.h"
#import "MITShuttleStopViewController.h"
#import "MITCalloutMapView.h"
#import "SMCalloutView.h"
#import "MITTiledMapView.h"
#import "MITLocationManager.h"
#import "MITTileOverlay.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";
NSString * const kMITShuttleMapBusAnnotationViewReuseIdentifier = @"kMITShuttleMapBusAnnotationViewReuseIdentifier";

static const NSTimeInterval kVehiclesRefreshInterval = 10.0;

static const CGFloat kMapAnnotationAlphaDefault = 1.0;

typedef NS_OPTIONS(NSUInteger, MITShuttleStopState) {
    MITShuttleStopStateDefault  = 0,
    MITShuttleStopStateSelected = 1 << 0,
    MITShuttleStopStateNext     = 1 << 1,
};

@interface MITShuttleMapViewController () <MKMapViewDelegate, NSFetchedResultsControllerDelegate, SMCalloutViewDelegate, MITShuttleStopViewControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *routesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *stopsFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *vehiclesFetchedResultsController;

@property (nonatomic, readonly) NSArray *routes;
@property (nonatomic, readonly) NSArray *stops;
@property (nonatomic, readonly) NSArray *vehicles;

@property (nonatomic, strong) NSTimer *vehiclesRefreshTimer;
@property (nonatomic) BOOL hasSetUpMapRect;
@property (nonatomic, strong) NSArray *routeSegmentPolylines;

@property (nonatomic) BOOL shouldAnimateBusUpdate;
@property (nonatomic) BOOL shouldRepositionMapOnRotate;
@property (nonatomic) BOOL touchesActive;

@property (nonatomic, strong) SMCalloutView *calloutView;
@property (nonatomic, strong) MITShuttleStopViewController *calloutStopViewController;

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) NSLayoutConstraint *toolbarBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *mapBottomConstraint;

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
    [self.tiledMapView setMapDelegate:self];
    self.tiledMapView.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
    self.tiledMapView.mapView.tintColor = [UIColor mit_systemTintColor];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self setState:self.state animated:NO];
        [self setupToolbar];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareForViewAppearance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.hasSetUpMapRect && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self setupMapBoundingBoxAnimated:NO];
        self.hasSetUpMapRect = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self prepareForViewDisappearance];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [super viewWillDisappear:animated];
}

- (void)prepareForViewAppearance
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self startRefreshingVehicles];
        
        if (!self.hasSetUpMapRect) {
            [self setupMapBoundingBoxAnimated:NO];
            self.hasSetUpMapRect = YES;
        }
    }

    [self setupTileOverlays];
    self.shouldAnimateBusUpdate = NO;
    [self performFetch];
}

- (void)prepareForViewDisappearance
{
    // This seems to prevent a crash with a VKRasterOverlayTileSource being deallocated and sent messages
    [self.tiledMapView.mapView removeOverlays:self.tiledMapView.mapView.overlays];
    
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
            self.tiledMapView.mapView.scrollEnabled = NO;
            self.tiledMapView.mapView.zoomEnabled = NO;
            
            break;
        }
        case MITShuttleMapStateExpanding: {
            self.tiledMapView.mapView.scrollEnabled = YES;
            self.tiledMapView.mapView.zoomEnabled = YES;
            
            break;
        }
            
        case MITShuttleMapStateContracted: {
            if (!self.stop) {
                [self setupMapBoundingBoxAnimated:animated];
            }
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
    if ([_stop isEqual:stop]) {
        return;
    }
    
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

#pragma mark - Stop Centering

- (void)centerToShuttleStop:(MITShuttleStop *)stop animated:(BOOL)animated
{
    NSArray *annotations = self.tiledMapView.mapView.annotations;
    [self.tiledMapView.mapView removeAnnotations:annotations];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(stop.coordinate, 50, 50);
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            [self.tiledMapView.mapView setRegion:region];
        } completion:^(BOOL finished) {
            [self.tiledMapView.mapView addAnnotations:annotations];
        }];
    } else {
        [self.tiledMapView.mapView addAnnotations:annotations];
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)routesFetchedResultsController
{
    if (!_routesFetchedResultsController) {
        NSPredicate *predicate = nil;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"SELF = %@", self.route];
        }
        _routesFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleRoute" predicate:predicate];
    }
    return _routesFetchedResultsController;
}

- (NSFetchedResultsController *)stopsFetchedResultsController
{
    if (!_stopsFetchedResultsController) {
        NSPredicate *predicate = nil;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"routes contains %@", self.route];
        }
        _stopsFetchedResultsController = [self fetchedResultsControllerForEntityWithName:@"ShuttleStop" predicate:predicate];
    }
    return _stopsFetchedResultsController;
}

- (NSFetchedResultsController *)vehiclesFetchedResultsController
{
    if (!_vehiclesFetchedResultsController) {
        NSPredicate *predicate = nil;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"route = %@", self.route];
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
        [self.tiledMapView.mapView addAnnotation:anObject];
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoute];
    }
}

- (void)removeObject:(id)anObject
{
    if ([anObject conformsToProtocol:@protocol(MKAnnotation)]) {
        [self.tiledMapView.mapView removeAnnotation:anObject];
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoute];
    }
}

- (void)updateObject:(id)anObject
{
    if ([anObject conformsToProtocol:@protocol(MKAnnotation)]) {
        if ([anObject isKindOfClass:[MITShuttleVehicle class]]) {
            if (self.shouldAnimateBusUpdate) {
                [anObject setCoordinate:((MITShuttleVehicle *)anObject).coordinate];
            } else {
                [self removeObject:anObject];
                [self addObject:anObject];
            }
        } else if (anObject == self.stop) {
            // do nothing, otherwise callout will be dismissed
        } else {
            [self removeObject:anObject];
            [self addObject:anObject];
        }
    } else if ([anObject isKindOfClass:[MITShuttleRoute class]]) {
        [self refreshRoute];
    }
}

#pragma mark - Public Methods

- (void)setRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    // Are we actually changing routes?
    BOOL needsRouteChange = ![self.route isEqual:route];
    BOOL needsStopChange = ![self.stop isEqual:stop];
    
    id<MKAnnotation> selectedAnnotation = nil;
    if (self.tiledMapView.mapView.selectedAnnotations.count > 0) {
        selectedAnnotation = self.tiledMapView.mapView.selectedAnnotations[0];
    }
    
    if (needsRouteChange) {
        if (needsStopChange && selectedAnnotation) {
            [self.tiledMapView.mapView deselectAnnotation:selectedAnnotation animated:YES];
        }

        // TODO: Wait until deselect is complete
        self.route = route;
        self.stop = stop;
        [self resetFetchedResults];
        self.shouldRepositionMapOnRotate = YES;
     
        // TODO: Modify bounding box to include space for callout, ie center the annotation
        [self setupMapBoundingBoxAnimated:YES];
        
        // TODO: Wait for bounds change
        if (needsStopChange && stop) {
            // wait until map region change animation completes
            // TODO: Fix this to make it robust and less hacky! E.g. what happens if we mash multiple annotations?
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tiledMapView.mapView selectAnnotation:stop animated:YES];
            });
        }
    } else if (needsStopChange) {
        if (selectedAnnotation) {
            [self.tiledMapView.mapView deselectAnnotation:selectedAnnotation animated:YES];
        }
        if (stop) {
            [self.tiledMapView.mapView selectAnnotation:stop animated:YES];
        }
    }
}

- (void)routeUpdated
{
    [self refreshStopAnnotationImages];
    self.shouldAnimateBusUpdate = YES;
}

- (void)setMapToolBarHidden:(BOOL)hidden
{
    if (hidden) {
        self.toolbarBottomConstraint.constant = self.toolbar.bounds.size.height;
    } else {
        self.toolbarBottomConstraint.constant = 0;
    }
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
    if (!self.stop) {
        MKCoordinateRegion region;
        MITShuttleRoute *route = self.route;
        if ([route pathSegmentsAreValid]) {
            region = [route encompassingMapRegion];
        } else {
            // Center on the MIT Campus with custom map tiles
            region = kMITShuttleDefaultMapRegion;
        }
        
        [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
        [self.tiledMapView.mapView setRegion:region animated:NO]; // Animated to NO to prevent map kit issue where animating the map causes the bounding box to be zoomed out to far sometimes.
    } else {
        [self centerToShuttleStop:self.stop animated:animated];
    }
}

- (CGRect)rectForAnnotationView:(MKAnnotationView *)annotationView inView:(UIView *)view
{
    CGPoint center = [self.tiledMapView.mapView convertCoordinate:annotationView.annotation.coordinate toPointToView:self.tiledMapView.mapView];
    CGSize size = annotationView.frame.size;
    CGRect mapViewRect = CGRectMake(center.x - size.width / 2, center.y - size.height / 2, size.width, size.height);
    return [self.tiledMapView.mapView convertRect:mapViewRect toView:view];
}

- (void)exitMapStateButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewControllerExitFullscreenButtonPressed:)]) {
        [self.delegate shuttleMapViewControllerExitFullscreenButtonPressed:self];
    }
}

- (void)setupToolbar
{
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Using UIButton here because setting barButtonWithImage positions very weirdly.
    UIButton *exitMapStateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *exitMapStateImage = [UIImage imageNamed:MITImageBarButtonList];
    [exitMapStateButton setImage:exitMapStateImage forState:UIControlStateNormal];
    [exitMapStateButton addTarget:self action:@selector(exitMapStateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [exitMapStateButton setTintColor:[UIColor mit_tintColor]];
    exitMapStateButton.frame = CGRectMake(0, 0, exitMapStateImage.size.width, exitMapStateImage.size.height);
    UIBarButtonItem *exitMapStateBarButton = [[UIBarButtonItem alloc] initWithCustomView:exitMapStateButton];
    [self.toolbar setItems:@[self.tiledMapView.userLocationButton,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             exitMapStateBarButton] animated:NO];
    [self.view addSubview:self.toolbar];
    
    NSArray *horizontalToolbarConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[toolbar]-0-|" options:0 metrics:nil views:@{@"toolbar": self.toolbar}];
    [self.view addConstraints:horizontalToolbarConstraints];
    
    NSLayoutConstraint *toolbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
    [self.view addConstraint:toolbarHeightConstraint];
    
    [self.view removeConstraint:self.mapBottomConstraint];
    self.mapBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tiledMapView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.toolbar attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.mapBottomConstraint];
    
    self.toolbarBottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:self.toolbar.bounds.size.height];
    [self.view addConstraint:self.toolbarBottomConstraint];
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
    
    [self.tiledMapView.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)setupBaseTileOverlay
{
    static NSString * const template = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}";
    
    MKTileOverlay *baseTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    baseTileOverlay.canReplaceMapContent = YES;
    
    [self.tiledMapView.mapView addOverlay:baseTileOverlay level:MKOverlayLevelAboveLabels];
}

#pragma mark - Overlays/Annotations

- (void)refreshAll
{
    [self refreshRoute];
    [self refreshStops];
    [self refreshVehicles];
}

- (void)refreshRoute
{
    if (self.route && ![self.route pathSegmentsAreValid]) {
        return;
    }
    
    [self.tiledMapView.mapView removeOverlays:self.routeSegmentPolylines];
    
    self.routeSegmentPolylines = [self.route pathSegmentPolylines];
    if ([self.routeSegmentPolylines count] > 0) {
        [self.tiledMapView.mapView addOverlays:self.routeSegmentPolylines];
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
    // Leave this to prevent crash when an annotation is selected and the view controller is navigated away.
    for (id<MKAnnotation> annotation in self.tiledMapView.mapView.selectedAnnotations) {
        [self.tiledMapView.mapView deselectAnnotation:annotation animated:NO];
    }
    
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.tiledMapView.mapView.annotations) {
        if ([annotation isKindOfClass:class] && annotation != self.stop) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.tiledMapView.mapView removeAnnotations:annotationsToRemove];
}

- (void)refreshStopAnnotationImages
{
    for (MITShuttleStop *stop in self.stops) {
        MKAnnotationView *annotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
        [UIView transitionWithView:annotationView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            annotationView.image = [self annotationViewImageForStop:stop];
        } completion:nil];
    }
}

- (UIImage *)annotationViewImageForStop:(MITShuttleStop *)stop
{
    if (self.shouldUsePinAnnotations) {
        return [UIImage imageNamed:MITImageMapAnnotationPlacePin];
    }
    else {
        MITShuttleStopState state = MITShuttleStopStateDefault;
        if ([self.route.nextStops containsObject:stop]) {
            state = state | MITShuttleStopStateNext;
        }
        if ([self.stop isEqual:stop]) {
            state = state | MITShuttleStopStateSelected;
        }
        
        if (state == MITShuttleStopStateDefault) {
            return [UIImage imageNamed:MITImageShuttlesAnnotationCurrentStop];
        } else if (state == MITShuttleStopStateNext) {
            return [UIImage imageNamed:MITImageShuttlesAnnotationNextStop];
        } else if (state == MITShuttleStopStateSelected) {
            return [UIImage imageNamed:MITImageShuttlesAnnotationCurrentStopSelected] ;
        } else if (state == (MITShuttleStopStateNext | MITShuttleStopStateSelected)) {
            return [UIImage imageNamed:MITImageShuttlesAnnotationNextStopSelected];
        }
        return nil;
    }
}

- (CGFloat)annotationViewAlphaForStop:(MITShuttleStop *)stop
{
    return kMapAnnotationAlphaDefault;
}

- (CGFloat)annotationViewAlphaForVehicle:(MITShuttleVehicle *)vehicle
{
    return kMapAnnotationAlphaDefault;
}

- (CGFloat)overlayAlphaForPolyline:(MKPolyline *)polyline
{
    return kMapAnnotationAlphaDefault;
}

#pragma mark - Bus Annotation Animations

- (void)startAnimatingBusAnnotations
{
    for (id <MKAnnotation> annotation in self.tiledMapView.mapView.annotations) {
        if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
            [(MITShuttleMapBusAnnotationView *)[self.tiledMapView.mapView viewForAnnotation:annotation] startAnimating];
        }
    }
}

- (void)stopAnimatingBusAnnotations
{
    for (id <MKAnnotation> annotation in self.tiledMapView.mapView.annotations) {
        if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
            [(MITShuttleMapBusAnnotationView *)[self.tiledMapView.mapView viewForAnnotation:annotation] stopAnimating];
        }
    }
}

#pragma mark - Custom Callout

- (void)setupCalloutView
{
    SMCalloutView *calloutView = [[SMCalloutView alloc] initWithFrame:CGRectZero];
    calloutView.contentViewMargin = 0;
    calloutView.anchorMargin = 39;
    calloutView.delegate = self;
    calloutView.permittedArrowDirection = SMCalloutArrowDirectionAny;
    
    self.calloutView = calloutView;
    self.tiledMapView.mapView.calloutView = calloutView;
}

- (void)presentPadCalloutForStop:(MITShuttleStop *)stop
{
    MKAnnotationView *stopAnnotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
    
    // TODO: Correctly initialize this
    // TODO: Figure out how to correctly add the VC as a child VC
    MITShuttleStopViewController *stopViewController = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStylePlain stop:stop route:self.route predictionLoader:nil];
    stopViewController.tableTitle = stop.title;
    stopViewController.delegate = self;
    
    CGSize size = CGSizeZero;
    if (self.route) {
        stopViewController.viewOption = MITShuttleStopViewOptionAll;
        size = CGSizeMake(320, 320);
    } else {
        stopViewController.viewOption = MITShuttleStopViewOptionIntersectingOnly;
        stopViewController.shouldHideFooter = YES;
        stopViewController.tableView.scrollEnabled = NO;
        size = CGSizeMake(320, [stopViewController preferredContentHeight]);
    }
    [stopViewController setFixedContentSize:size];
    CGRect frame = stopViewController.view.frame;
    frame.size = size;
    stopViewController.view.frame = frame;
    self.calloutStopViewController = stopViewController;
    
    [self addChildViewController:stopViewController];
    [stopViewController didMoveToParentViewController:self];
    
    [self setupCalloutView];
    
    self.calloutView.contentView = stopViewController.view;
    self.calloutView.calloutOffset = stopAnnotationView.calloutOffset;
    
    [self.calloutView presentCalloutFromRect:stopAnnotationView.bounds inView:stopAnnotationView constrainedToView:self.tiledMapView.mapView animated:YES];
}

- (void)presentPhoneCalloutForStop:(MITShuttleStop *)stop
{
    MKAnnotationView *stopAnnotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
    
    [self setupCalloutView];
    
    self.calloutView.contentView = nil;
    self.calloutView.title = stop.title;
    
    NSString *calloutSubtitle = nil;
    switch ([self.route status]) {
        case MITShuttleRouteStatusNotInService: {
            calloutSubtitle = @"Not in service";
            break;
        }
        case MITShuttleRouteStatusInService: {
            MITShuttlePrediction *nextPrediction = [stop nextPredictionForRoute:self.route];
            
            if (nextPrediction == nil) {
                calloutSubtitle = @"No current predictions";
                break;
            }
            
            NSString *arrivalTime = nil;
            NSInteger minutesLeft = floor([nextPrediction.seconds doubleValue] / 60);
            if (minutesLeft < 1) {
                arrivalTime = @"now";
            } else {
                arrivalTime = [NSString stringWithFormat:@"in %li minutes", (long)minutesLeft];
            }
            calloutSubtitle = [NSString stringWithFormat:@"Arriving %@", arrivalTime];
            break;
        }
        case MITShuttleRouteStatusPredictionsUnavailable: {
            calloutSubtitle = @"No current predictions";
            break;
        }
        default: {
            calloutSubtitle = @"No current predictions";
            break;
        }
    }
    
    self.calloutView.subtitle = calloutSubtitle;
    
    UIImageView *chevronImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
    chevronImageView.contentMode = UIViewContentModeRight;
    self.calloutView.rightAccessoryView = chevronImageView;
    
    self.calloutView.calloutOffset = stopAnnotationView.calloutOffset;
    [self.calloutView presentCalloutFromRect:stopAnnotationView.bounds inView:stopAnnotationView constrainedToView:self.tiledMapView.mapView animated:YES];
}

- (void)dismissCurrentCallout
{
    [self.calloutView dismissCalloutAnimated:YES];
    
    [self.calloutStopViewController removeFromParentViewController];
    self.calloutStopViewController = nil;
}

#pragma mark - SMCalloutViewDelegate Methods

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset
{
    CGPoint adjustedCenter = CGPointMake(-offset.width + self.tiledMapView.mapView.bounds.size.width * 0.5,
                                         -offset.height + self.tiledMapView.mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [self.tiledMapView.mapView convertPoint:adjustedCenter toCoordinateFromView:self.tiledMapView.mapView];
    [self.tiledMapView.mapView setCenterCoordinate:newCenter animated:YES];
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView
{
    [self dismissCurrentCallout];
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didClickCalloutForStop:)]) {
        [self.delegate shuttleMapViewController:self didClickCalloutForStop:self.stop];
    }
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
        if (self.shouldUsePinAnnotations) {
            annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height / 2.0));
        } else {
            annotationView.centerOffset = CGPointZero;
        }
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
            [self presentPadCalloutForStop:stop];
        } else {
            [self presentPhoneCalloutForStop:stop];
        }
        
        if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectStop:)]) {
            [self.delegate shuttleMapViewController:self didSelectStop:stop];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    MITShuttleStop *stop = self.stop;
    self.stop = nil;
    
    [self dismissCurrentCallout];
    
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didDeselectStop:)]) {
        [self.delegate shuttleMapViewController:self didDeselectStop:stop];
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
    
    if (self.touchesActive) { // The user is touching and almost certainly manually repositioning the map
        self.shouldRepositionMapOnRotate = NO;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self startAnimatingBusAnnotations];
    [self refreshVehicles];
}

#pragma mark - MITShuttleStopViewControllerDelegate

- (void)shuttleStopViewController:(MITShuttleStopViewController *)shuttleStopViewController didSelectRoute:(MITShuttleRoute *)route
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectRoute:)]) {
        [self.delegate shuttleMapViewController:self didSelectRoute:route];
    }
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.tiledMapView.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}

#pragma mark - Map Pins Update

- (void)setShouldUsePinAnnotations:(BOOL)shouldUsePinAnnotations
{
    if (_shouldUsePinAnnotations != shouldUsePinAnnotations) {
        _shouldUsePinAnnotations = shouldUsePinAnnotations;
        NSArray *annotations = self.tiledMapView.mapView.annotations;
        [self.tiledMapView.mapView removeAnnotations:annotations];
        [self.tiledMapView.mapView addAnnotations:annotations];
    }
}

@end
