#import "MITMobiusMapViewController.h"

#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapBrowseContainerViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITLocationManager.h"
#import "MITMobiusDetailContainerViewController.h"
#import "MITMobiusCalloutContentView.h"
#import "MITMobiusModel.h"
#import "MITMobiusResourceView.h"
#import "MITMobiusMapObject.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";
static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";


@interface MITMobiusMapViewController () <MKMapViewDelegate, MITCalloutViewDelegate, MITMobiusDetailPagingDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MITMobiusMapObject *currentlySelectedRoom;
@property (nonatomic, strong) MKAnnotationView *resourceAnnotationView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic, strong) MITMobiusResource *resource;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;


@property(nonatomic,copy) NSArray *buildingSections;
@property(nonatomic,copy) NSDictionary *resourcesByBuilding;
@property(nonatomic,strong) NSMutableArray *buildings;


@end

@implementation MITMobiusMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupMapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIBarButtonItem *)userLocationButton
{
    return self.tiledMapView.userLocationButton;
}

#pragma mark - Map View

- (MITCalloutMapView *)mapView
{
    return self.tiledMapView.mapView;
}

- (void)setupMapView
{
    [self.tiledMapView setMapDelegate:self];
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
    
    [self recenterOnVisibleResources:NO];
    
    [self setupCalloutView];
}

- (void)setupCalloutView
{
    MITCalloutView *calloutView = [[MITCalloutView alloc] init];
    calloutView.delegate = self;
    calloutView.permittedArrowDirections = MITCalloutPermittedArrowDirectionAny;
    
    self.calloutView = calloutView;
    self.tiledMapView.mapView.mitCalloutView = self.calloutView;
}

- (void)setBuildingSections:(NSArray *)buildingSections setResourcesByBuilding:(NSDictionary *)resourcesByBuilding animated:(BOOL)animated
{
    self.buildingSections = buildingSections;
    self.resourcesByBuilding = resourcesByBuilding;
    
    NSMutableArray *buildings = [[NSMutableArray alloc] init];
    
    [buildingSections enumerateObjectsUsingBlock:^(NSString *roomName, NSUInteger idx, BOOL *stop) {
        
        MITMobiusMapObject *mapObject = [[MITMobiusMapObject alloc] initWithEntity:[MITMobiusMapObject entityDescription] insertIntoManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
        mapObject.roomName = roomName;
        
        NSArray *resources = [[[MITCoreDataController defaultController] mainQueueContext] transferManagedObjects:resourcesByBuilding[roomName]];
        mapObject.resources = [NSOrderedSet orderedSetWithArray:resources];
        MITMobiusResource *resource = [mapObject.resources firstObject];
        
        mapObject.latitude = resource.latitude;
        mapObject.longitude = resource.longitude;
        
        [buildings addObject:mapObject];
    }];
    
    if (![_buildings isEqualToArray:buildings]) {
        _buildings = buildings;
        
        [self _didChangeBuildings:animated];
    }
}

- (void)setBuildingSections:(NSArray *)buildingSections
{
    _buildingSections = buildingSections;
}

- (void)setResourcesByBuilding:(NSDictionary *)resourcesByBuilding
{
    _resourcesByBuilding = resourcesByBuilding;
}

- (NSMutableArray *)buildings
{
    if (!_buildings) {
        NSMutableArray *buildings = [[NSMutableArray alloc] init];
        _buildings = buildings;
    }
    return _buildings;
}

- (void)_didChangeBuildings:(BOOL)animated
{
    [self refreshPlaceAnnotations];
    [self recenterOnVisibleResources:animated];
}

#pragma mark - Map View

- (void)recenterOnVisibleResources:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region

    if ([self.buildings count]) {
        [self.mapView showAnnotations:self.buildings animated:NO];
        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:self.mapEdgeInsets animated:animated];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.buildings];
}

- (void)removeAllPlaceAnnotations
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITMobiusResource class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    
    [self.mapView removeAnnotations:annotationsToRemove];
}

- (void)showCalloutForResource:(MITMobiusResource *)resource
{
    if (resource) {
     
        [self.buildings enumerateObjectsUsingBlock:^(MITMobiusMapObject *mapObject, NSUInteger idx, BOOL *stop) {
            if ([mapObject.roomName isEqualToString:resource.room]) {
                [self.mapView selectAnnotation:mapObject animated:YES];
                (*stop = YES);
            }
        }];
        
    } else {
        [self.mapView selectAnnotation:nil animated:YES];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMobiusMapObject class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        NSInteger placeIndex = [self.buildings indexOfObject:annotation];
        [annotationView setNumber:(placeIndex + 1)];
        
        return annotationView;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self presentCalloutForMapView:mapView annotationView:view];
            self.resourceAnnotationView = view;
        } else {
            [self presentIPhoneCalloutForAnnotationView:view];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [self dismissCurrentCallout];
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]){
        [self.calloutView dismissCallout];
        self.currentlySelectedRoom = nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        
        MITMobiusMapObject *mapObject = (MITMobiusMapObject *)view.annotation;
        MITMobiusResource *resource = [mapObject.resources firstObject];
        [self pushDetailViewControllerForResource:resource];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.shouldRefreshAnnotationsOnNextMapRegionChange) {
        [self refreshPlaceAnnotations];
        self.shouldRefreshAnnotationsOnNextMapRegionChange = NO;
    }
    
    if (self.showFirstCalloutOnNextMapRegionChange) {
        if (self.buildings.count > 0) {
            [self showCalloutForResource:[self.buildings firstObject]];
        }
        
        self.showFirstCalloutOnNextMapRegionChange = NO;
    }
}

#pragma mark - Custom Callout

- (void)presentCalloutForMapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView
{
    
    MITMobiusMapObject *mapObject = (MITMobiusMapObject *)annotationView.annotation;
    MITMobiusResource *resource = [mapObject.resources firstObject];
    
    MITMobiusCalloutContentView *contentView = [[MITMobiusCalloutContentView alloc] init];
    contentView.resourceView.backgroundColor = [UIColor clearColor];
    contentView.resourceView.machineName = resource.name;
    contentView.resourceView.location = resource.room;
    [contentView.resourceView setStatus:MITMobiusResourceStatusOnline withText:resource.status];
    
    self.calloutView.contentView = contentView;
    self.calloutView.contentViewPreferredSize = [contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [self.calloutView presentFromRect:annotationView.bounds inView:annotationView withConstrainingView:self.tiledMapView.mapView];
}

- (void)dismissCurrentCallout
{
    [self.calloutView dismissCallout];
}

#pragma mark - Callout View

- (void)presentIPadCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMobiusMapObject *mapObject = (MITMobiusMapObject *)annotationView.annotation;
    MITMobiusResource *resource = [mapObject.resources firstObject];
    
    self.currentlySelectedRoom = mapObject;
    MITMobiusDetailContainerViewController *detailContainerViewController = [[MITMobiusDetailContainerViewController alloc] initWithResource:resource];
    detailContainerViewController.delegate = self;

    detailContainerViewController.view.frame = CGRectMake(0, 0, 320, 500);
    
    self.calloutView.contentView = detailContainerViewController.view;
    self.calloutView.contentView.clipsToBounds = YES;
    self.calloutViewController = detailContainerViewController;
    
    [self.calloutView presentFromRect:annotationView.bounds inView:annotationView withConstrainingView:self.tiledMapView.mapView];
    
    // We have to adjust the frame of the content view once its in the view hierarchy, because its constraints don't play nicely with SMCalloutView
    detailContainerViewController.view.frame = CGRectMake(0, 0, 320, 500);
}

- (void)presentIPhoneCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMobiusMapObject *mapObject = (MITMobiusMapObject *)annotationView.annotation;
    MITMobiusResource *resource = [mapObject.resources firstObject];
    
    self.currentlySelectedRoom = mapObject;
    self.calloutView.titleText = resource.room;

    [self.calloutView presentFromRect:annotationView.bounds inView:annotationView withConstrainingView:self.tiledMapView.mapView];
}

#pragma mark - SMCalloutViewDelegate Methods
- (void)calloutView:(MITCalloutView *)calloutView positionedOffscreenWithOffset:(CGPoint)offset
{
    MKMapView *mapView = self.mapView;
    CGPoint adjustedCenter = CGPointMake(-offset.x + mapView.bounds.size.width * 0.5,
                                         -offset.y + mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [mapView convertPoint:adjustedCenter toCoordinateFromView:mapView];
    [mapView setCenterCoordinate:newCenter animated:YES];
}

- (void)calloutViewTapped:(MITCalloutView *)calloutView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        
        MITMobiusMapObject *mapObject = self.currentlySelectedRoom;
        MITMobiusResource *resource = [mapObject.resources firstObject];
        
        [self pushDetailViewControllerForResource:resource];
    } else {
        
        [self presentIPadCalloutForAnnotationView:self.resourceAnnotationView];
    }
}

- (void)calloutViewRemovedFromViewHierarchy:(MITCalloutView *)calloutView
{
    /* Do Nothing */
}

- (void)pushDetailViewControllerForResource:(MITMobiusResource *)resource
{
    MITMobiusDetailContainerViewController *detailContainerViewController = [[MITMobiusDetailContainerViewController alloc] initWithResource:resource];
    detailContainerViewController.delegate = self;
    [self.navigationController pushViewController:detailContainerViewController animated:YES];
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}


#pragma mark - MITMobiusDetailPagingDelegate
- (NSUInteger)numberOfResourcesInDetailViewController:(MITMobiusDetailContainerViewController*)viewController
{
    // TODO: This approach needs some work, we should be keeping track of what chunk of data is being displayed,
    // not requiring the view controller to do it for us.
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    return resources.count;
}

- (MITMobiusResource*)detailViewController:(MITMobiusDetailContainerViewController*)viewController resourceAtIndex:(NSUInteger)index
{
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    return resources[index];
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResource:(MITMobiusResource*)resource
{
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    NSUInteger index = [resources indexOfObjectPassingTest:^BOOL(MITMobiusResource *otherResource, NSUInteger idx, BOOL *stop) {
        return [otherResource.identifier isEqualToString:resource.identifier];
    }];

    return index;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResourceWithIdentifier:(NSString*)resourceIdentifier
{
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    NSUInteger index = [resources indexOfObjectPassingTest:^BOOL(MITMobiusResource *otherResource, NSUInteger idx, BOOL *stop) {
        return [otherResource.identifier isEqualToString:resourceIdentifier];
    }];
    
    return index;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexAfterIndex:(NSUInteger)index
{
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    return (index + 1) % resources.count;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexBeforeIndex:(NSUInteger)index
{
    NSArray *resources = self.resourcesByBuilding[viewController.currentResource.room];
    return ((index + resources.count) - 1) % resources.count;
}

@end
