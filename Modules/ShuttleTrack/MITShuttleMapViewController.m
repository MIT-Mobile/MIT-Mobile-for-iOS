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
#import "MITTiledMapView.h"
#import "MITLocationManager.h"
#import "MITTileOverlay.h"
#import <QuartzCore/QuartzCore.h>
#import "MITShuttleVehiclesDataSource.h"
#import "MITShuttleVehicleList.h"
#import "MITCalloutView.h"

NSString * const kMITShuttleMapAnnotationViewReuseIdentifier = @"kMITShuttleMapAnnotationViewReuseIdentifier";
NSString * const kMITShuttleMapBusAnnotationViewReuseIdentifier = @"kMITShuttleMapBusAnnotationViewReuseIdentifier";

static CGFloat ToolbarHeight = 44.0;

static const NSTimeInterval kVehiclesRefreshInterval = 10.0;

static const CGFloat kMapAnnotationAlphaDefault = 1.0;

typedef NS_OPTIONS(NSUInteger, MITShuttleStopState) {
    MITShuttleStopStateDefault  = 0,
    MITShuttleStopStateSelected = 1 << 0,
    MITShuttleStopStateNext     = 1 << 1,
};

@interface MITShuttleMapViewController () <MKMapViewDelegate, NSFetchedResultsControllerDelegate, MITCalloutViewDelegate, MITShuttleStopViewControllerDelegate>

@property (nonatomic, strong) NSFetchRequest *routesFetchRequest;
@property (nonatomic, strong) MITShuttleVehiclesDataSource *vehiclesDataSource;

@property (nonatomic, strong) NSArray *routes;
@property (nonatomic, strong) NSArray *stops;
@property (nonatomic, strong) NSArray *vehicles;

@property (nonatomic, strong) NSTimer *vehiclesRefreshTimer;
@property (nonatomic) BOOL hasSetUpMapRect;
@property (nonatomic, strong) NSArray *routeSegmentPolylines;

@property (nonatomic) BOOL shouldRepositionMapOnRotate;
@property (nonatomic) BOOL touchesActive;

@property (nonatomic, strong) MITCalloutView *calloutView;
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
    
    [self setupVehiclesDataSource];
    
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
    
    // Prevent crash when an annotation is selected and the view controller is navigated away.
    for (id<MKAnnotation> annotation in self.tiledMapView.mapView.selectedAnnotations) {
        [self.tiledMapView.mapView deselectAnnotation:annotation animated:NO];
    }
}

- (void)prepareForViewAppearance
{
    [self startRefreshingVehicles];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (!self.hasSetUpMapRect) {
            [self setupMapBoundingBoxAnimated:NO];
            self.hasSetUpMapRect = YES;
        }
    }

    [self setupTileOverlays];
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

#pragma mark - Load Vehicles

- (void)setupVehiclesDataSource
{
    self.vehiclesDataSource = [[MITShuttleVehiclesDataSource alloc] init];
    
    // We always wants to pull all vehicles into Core Data so there isn't a significant delay in route status or vehicle position when returning to "all routes" mode
    // The VehiclesDataSource will take care of fetching the correct ones for our route once they are all saved
    self.vehiclesDataSource.forceUpdateAllVehicles = YES;
    
    
    self.vehiclesDataSource.route = self.route;
}

- (void)loadVehicles
{
    [self.vehiclesDataSource updateVehicles:^(MITShuttleVehiclesDataSource *dataSource, NSError *error) {
        self.vehicles = dataSource.vehicles;
        [self refreshVehicles];
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
        [self.tiledMapView.mapView setRegion:region];
        [self.tiledMapView.mapView addAnnotations:annotations];
    }
}

#pragma mark - Fetch Requests

- (NSFetchRequest *)routesFetchRequest
{
    if (!_routesFetchRequest) {
        _routesFetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITShuttleRoute entityName]];
        
        NSPredicate *predicate = nil;
        if (self.route) {
            predicate = [NSPredicate predicateWithFormat:@"SELF = %@", self.route];
        }
        [_routesFetchRequest setPredicate:predicate];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO];
        [_routesFetchRequest setSortDescriptors:@[sortDescriptor]];
    }
    
    return _routesFetchRequest;
}

- (void)resetFetchedResults
{
    self.routesFetchRequest = nil;
    [self performFetch];
}

#pragma mark - Annotation Management

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
            MITShuttleMapBusAnnotationView *annotationView = (MITShuttleMapBusAnnotationView *)[self.tiledMapView.mapView viewForAnnotation:anObject];
            [annotationView updateViewAnimated:NO];
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
        if (selectedAnnotation) {
            [self.tiledMapView.mapView deselectAnnotation:selectedAnnotation animated:YES];
        }

        // TODO: Wait until deselect is complete
        [self.tiledMapView.mapView removeAnnotations:self.tiledMapView.mapView.annotations];
        self.shouldRepositionMapOnRotate = YES;
        
        // TODO: Modify bounding box to include space for callout, ie center the annotation
        [self setupMapBoundingBoxAnimated:YES];
        
        self.route = route;
        self.stop = stop;
        self.vehiclesDataSource.route = route;
        [self resetFetchedResults];
        
        // TODO: Wait for bounds change
        if (stop) {
            // wait until map region change animation completes
            // TODO: Fix this to make it robust and less hacky! E.g. what happens if we mash multiple annotations?
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self selectAnnotationForStop:stop];
            });
        }
    } else if (needsStopChange) {
        if (selectedAnnotation) {
            [self.tiledMapView.mapView deselectAnnotation:selectedAnnotation animated:YES];
        }
        if (stop) {
            [self selectAnnotationForStop:stop];
        }
    }
}

- (void)selectAnnotationForStop:(MITShuttleStop *)stop
{
    if ([self.tiledMapView.mapView.annotations containsObject:stop]) {
        [self.tiledMapView.mapView selectAnnotation:stop animated:YES];
    } else {
        // It's possible that the annotation hasn't been added since we're filtering duplicates
        for (id<MKAnnotation>annotation in self.tiledMapView.mapView.annotations) {
            if ([annotation isKindOfClass:[MITShuttleStop class]]) {
                if ([[(MITShuttleStop *)annotation identifier] isEqualToString:stop.identifier]) {
                    [self.tiledMapView.mapView selectAnnotation:annotation animated:YES];
                    break;
                }
            }
        }
    }
}

- (void)routeUpdated
{
    [self refreshStopAnnotationImagesAnimated:YES];
    [self fetchVehicles:^{
        [self refreshVehicles];
    }];
}

- (void)setMapToolBarHidden:(BOOL)hidden
{
    if (hidden) {
        self.toolbarBottomConstraint.constant = ToolbarHeight;
    } else {
        self.toolbarBottomConstraint.constant = 0;
    }
}

#pragma mark - Private Methods

- (void)updateStops
{
    if (self.route != nil) {
        self.stops = [self.route.stops array];
    } else {
        NSMutableArray *newStops = [NSMutableArray array];
        for (MITShuttleRoute *route in self.routes) {
            [newStops addObjectsFromArray:[route.stops array]];
        }
        self.stops = [NSArray arrayWithArray:newStops];
    }
}

- (void)performFetch
{
    dispatch_group_t fetchGroup = dispatch_group_create();
    dispatch_group_enter(fetchGroup);
    dispatch_group_enter(fetchGroup);
    dispatch_group_notify(fetchGroup, dispatch_get_main_queue(), ^{
        [self updateStops];
        [self refreshAll];
    });
    
    [self fetchRoutes:^{
        dispatch_group_leave(fetchGroup);
    }];
    
    [self fetchVehicles:^{
        dispatch_group_leave(fetchGroup);
    }];
}

- (void)fetchRoutes:(void(^)(void))completion
{
    [[MITCoreDataController defaultController] performBackgroundFetch:self.routesFetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
        NSMutableArray *newRoutes = [NSMutableArray array];
        for (NSManagedObjectID *objectId in fetchedObjectIDs) {
            NSManagedObject *route = [[[MITCoreDataController defaultController] mainQueueContext] existingObjectWithID:objectId error:nil];
            if (route) {
                [newRoutes addObject:route];
            }
        }
        self.routes = [NSArray arrayWithArray:newRoutes];
        if (completion) {
            completion();
        }
    }];
}

- (void)fetchVehicles:(void(^)(void))completion
{
    [self.vehiclesDataSource fetchVehiclesWithoutUpdating:^(MITShuttleVehiclesDataSource *dataSource, NSError *error) {
        self.vehicles = dataSource.vehicles;
        if (completion) {
            completion();
        }
    }];
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
    for (id<MKAnnotation> annotation in self.tiledMapView.mapView.selectedAnnotations) {
        [self.tiledMapView.mapView deselectAnnotation:annotation animated:NO];
    }
    
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
    
    NSLayoutConstraint *toolbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:ToolbarHeight];
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
    static NSString * const template = @"https://m.mit.edu/api/arcgis/WhereIs_Base_Topo/MapServer/tile/{z}/{y}/{x}";
    
    MITTileOverlay *tileOverlay = [[MITTileOverlay alloc] initWithURLTemplate:template];
    tileOverlay.canReplaceMapContent = YES;
    
    [self.tiledMapView.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)setupBaseTileOverlay
{
    static NSString * const template = @"https://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}";
    
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
    NSMutableArray *addedStopIdentifiers = [NSMutableArray array];
    for (MITShuttleStop *stop in self.stops) {
        if (![addedStopIdentifiers containsObject:stop.identifier]) {
            [self addObject:stop];
            [addedStopIdentifiers addObject:stop.identifier];
        }
    }
}

- (void)refreshVehicles
{
    NSMutableIndexSet *newVehicleIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.vehicles.count)];
    for (id<MKAnnotation> annotation in self.tiledMapView.mapView.annotations) {
        if ([annotation isKindOfClass:[MITShuttleVehicle class]]) {
            if ([self.vehicles containsObject:annotation]) {
                [self updateObject:annotation];
                [newVehicleIndexes removeIndex:[self.vehicles indexOfObject:annotation]];
            } else {
                [self removeObject:annotation];
            }
        }
    }
    [newVehicleIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self addObject:[self.vehicles objectAtIndex:idx]];
    }];
}

- (void)removeMapAnnotationsForClass:(Class)class
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.tiledMapView.mapView.annotations) {
        if ([annotation isKindOfClass:class] && annotation != self.stop) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.tiledMapView.mapView removeAnnotations:annotationsToRemove];
}

- (void)refreshStopAnnotationImagesAnimated:(BOOL)animated
{
    if (animated) {
        for (MITShuttleStop *stop in self.stops) {
            MKAnnotationView *annotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
            [UIView transitionWithView:annotationView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [self setupStopAnnotationView:annotationView];
            } completion:nil];
        }
    } else {
        for (MITShuttleStop *stop in self.stops) {
            MKAnnotationView *annotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
            [self setupStopAnnotationView:annotationView];
        }
    }
}

- (void)setupStopAnnotationView:(MKAnnotationView *)annotationView
{
    if (self.shouldUsePinAnnotations) {
        annotationView.image = [UIImage imageNamed:MITImageMapAnnotationPlacePin];
        annotationView.centerOffset = CGPointMake(8.0, -15.0);
        annotationView.calloutOffset = CGPointMake(-9.0, -1.0);
    }
    else {
        annotationView.image = [UIImage imageNamed:MITImageShuttlesAnnotationCurrentStop];
        annotationView.centerOffset = CGPointZero;
        annotationView.calloutOffset = CGPointMake(0.0, 3.0);
    }
    annotationView.alpha = kMapAnnotationAlphaDefault;
}

- (UIImage *)annotationViewImageForStop:(MITShuttleStop *)stop
{
    if (self.shouldUsePinAnnotations) {
        return [UIImage imageNamed:MITImageMapAnnotationPlacePin];
    }
    else {
        return [UIImage imageNamed:MITImageShuttlesAnnotationCurrentStop];
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

- (void)cancelBusAnnotationAnimations
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
    if (!self.calloutView) {
        // TODO: Lazy load?
        MITCalloutView *calloutView = [MITCalloutView new];
        calloutView.delegate = self;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            calloutView.permittedArrowDirections = MITCalloutArrowDirectionTop | MITCalloutArrowDirectionBottom;
        }
        self.calloutView = calloutView;
        self.tiledMapView.mapView.mitCalloutView = calloutView;
    }
}

- (void)presentPadCalloutForStop:(MITShuttleStop *)stop
{
    [self dismissCurrentCalloutAnimated:NO];
    MKAnnotationView *stopAnnotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
    
    MITShuttleStopViewController *stopViewController = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped stop:stop route:self.route];
    stopViewController.title = stop.title;
    stopViewController.delegate = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:stopViewController];
    nav.navigationBar.translucent = NO;
    
    CGSize size = CGSizeZero;
    if (self.route) {
        stopViewController.viewOption = MITShuttleStopViewOptionAll;
        size = CGSizeMake(320, 320);
    } else {
        stopViewController.viewOption = MITShuttleStopViewOptionIntersectingOnly;
        stopViewController.shouldHideFooter = YES;
        stopViewController.tableView.scrollEnabled = NO;
        size = CGSizeMake(320, [stopViewController preferredContentHeight] + 10);
    }
    CGRect frame = stopViewController.view.frame;
    
    // Adjust nav height to accomodate nav bar
    size.height += CGRectGetHeight(nav.navigationBar.bounds);
    frame.size = size;
    nav.view.frame = frame;
    
    self.calloutStopViewController = stopViewController;
    
    [nav willMoveToParentViewController:self];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    
    [self setupCalloutView];
    self.calloutView.shouldHighlightOnTouch = NO;
    self.calloutView.internalInsets = UIEdgeInsetsZero;
    self.calloutView.externalInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame) + 10, 10, 10, 10);
    self.calloutView.contentView = nav.view;
    
    CGRect bounds = stopAnnotationView.bounds;
    if (self.shouldUsePinAnnotations) {
        bounds.size.width /= 2.0;
    }
    [self.calloutView presentFromRect:bounds inView:stopAnnotationView withConstrainingView:self.tiledMapView.mapView];
}

- (void)presentPhoneCalloutForStop:(MITShuttleStop *)stop
{
    MKAnnotationView *stopAnnotationView = [self.tiledMapView.mapView viewForAnnotation:stop];
    
    [self setupCalloutView];
    
    self.calloutView.contentView = nil;
    self.calloutView.titleText = stop.title;
    
    NSString *calloutSubtitle = nil;
    switch ([self.route status]) {
        case MITShuttleRouteStatusNotInService: {
            calloutSubtitle = @"Not in service";
            break;
        }
        case MITShuttleRouteStatusInService: {
            MITShuttlePrediction *nextPrediction = [stop nextPrediction];
            
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
        case MITShuttleRouteStatusUnknown: {
            calloutSubtitle = @"No current predictions";
            break;
        }
        default: {
            calloutSubtitle = @"No current predictions";
            break;
        }
    }
    
    self.calloutView.subtitleText = calloutSubtitle;
    
    CGRect bounds = stopAnnotationView.bounds;
    bounds.size.width /= 2.0;
    [self.calloutView presentFromRect:bounds inView:stopAnnotationView withConstrainingView:self.tiledMapView.mapView];
}

- (void)dismissCurrentCalloutAnimated:(BOOL)animated
{
    [self.calloutView dismissCallout];
}

#pragma mark - MITCalloutViewDelegate Methods

- (void)calloutView:(MITCalloutView *)calloutView positionedOffscreenWithOffset:(CGPoint)offscreenOffset
{
    CGPoint adjustedCenter = CGPointMake(offscreenOffset.x + self.tiledMapView.mapView.bounds.size.width * 0.5,
                                         offscreenOffset.y + self.tiledMapView.mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [self.tiledMapView.mapView convertPoint:adjustedCenter toCoordinateFromView:self.tiledMapView.mapView];
    [self.tiledMapView.mapView setCenterCoordinate:newCenter animated:YES];
}

- (void)calloutViewTapped:(MITCalloutView *)calloutView
{
    [self dismissCurrentCalloutAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didClickCalloutForStop:)]) {
        [self.delegate shuttleMapViewController:self didClickCalloutForStop:self.stop];
    }
}

- (void)calloutViewRemovedFromViewHierarchy:(MITCalloutView *)calloutView {
    [self.calloutStopViewController willMoveToParentViewController:nil];
    [self.calloutStopViewController removeFromParentViewController];
    calloutView.contentView = nil;
    [self.calloutStopViewController didMoveToParentViewController:nil];
    self.calloutStopViewController = nil;
}

#pragma mark - MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else if ([annotation isKindOfClass:[MITShuttleStop class]]) {
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITShuttleMapAnnotationViewReuseIdentifier];
        }
        [self setupStopAnnotationView:annotationView];
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
            view.layer.zPosition = -1;
        } else {
            view.layer.zPosition = 0;
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
    
    [self dismissCurrentCalloutAnimated:YES];
    
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
    [self cancelBusAnnotationAnimations];
    
    if (self.touchesActive) { // The user is touching and almost certainly manually repositioning the map
        self.shouldRepositionMapOnRotate = NO;
    }
}

#pragma mark - MITShuttleStopViewControllerDelegate

- (void)shuttleStopViewController:(MITShuttleStopViewController *)shuttleStopViewController didSelectRoute:(MITShuttleRoute *)route withStop:(MITShuttleStop *)stop
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewController:didSelectRoute:withStop:)]) {
        [self.delegate shuttleMapViewController:self didSelectRoute:route withStop:stop];
    }
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.tiledMapView.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}

@end
