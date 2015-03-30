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
#import "MITMobiusRoomObject.h"
#import "MITMobiusRootPhoneViewController.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";
static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";


@interface MITMobiusMapViewController () <MKMapViewDelegate, MITCalloutViewDelegate, MITMobiusDetailPagingDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MITMobiusRoomObject *currentlySelectedRoom;
@property (nonatomic, strong) MKAnnotationView *resourceAnnotationView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic, strong) MITMobiusResource *resource;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;
@property (nonatomic) NSInteger selectedIndex;

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

- (void)reloadMapAnimated:(BOOL)animated
{
    [self _didChangeBuildings:animated];
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
    
    if ([self.dataSource numberOfRoomsForViewController:self]) {
        [self.mapView showAnnotations:[self.mapView annotations] animated:NO];
        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:self.mapEdgeInsets animated:animated];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self makeStuff];
}

- (void)makeStuff
{
    NSInteger numberOfRooms = [self.dataSource numberOfRoomsForViewController:self];
    for (NSInteger roomIndex = 0 ; roomIndex < numberOfRooms ; roomIndex++) {
        MITMobiusRoomObject *room = [self.dataSource viewController:self roomAtIndex:roomIndex];
        room.index = roomIndex;
        [self.mapView addAnnotation:room];
    }
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

- (void)showCalloutForRoom:(MITMobiusRoomObject *)room
{
    if (room) {
        [self.mapView selectAnnotation:room animated:YES];
    } else {
        [self.mapView selectAnnotation:nil animated:YES];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMobiusRoomObject class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        MITMobiusRoomObject *room = (MITMobiusRoomObject *)annotation;
        [annotationView setNumber:(room.index + 1)];
        
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
        
        MITMobiusRoomObject *mapObject = (MITMobiusRoomObject *)view.annotation;
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
        if ([self.dataSource numberOfRoomsForViewController:self] > 0) {
            [self showCalloutForRoom:[self.dataSource viewController:self roomAtIndex:0]];
        }
        
        self.showFirstCalloutOnNextMapRegionChange = NO;
    }
}

#pragma mark - Custom Callout

- (void)presentCalloutForMapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView
{
    MITMobiusRoomObject *mapObject = (MITMobiusRoomObject *)annotationView.annotation;
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
    MITMobiusRoomObject *mapObject = (MITMobiusRoomObject *)annotationView.annotation;
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
    MITMobiusRoomObject *mapObject = (MITMobiusRoomObject *)annotationView.annotation;
    self.selectedIndex = mapObject.index;

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
        
        MITMobiusRoomObject *mapObject = self.currentlySelectedRoom;
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
    NSInteger number = [self.dataSource viewController:self numberOfResourcesInRoomAtIndex:self.selectedIndex];
    return number;
}

- (MITMobiusResource*)detailViewController:(MITMobiusDetailContainerViewController*)viewController resourceAtIndex:(NSUInteger)index
{
    MITMobiusResource *resource = [self.dataSource viewController:self resourceAtIndex:index inRoomAtIndex:self.selectedIndex];
    return resource;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResource:(MITMobiusResource*)resource
{
    MITMobiusRoomObject *room = [self.dataSource viewController:self roomAtIndex:self.selectedIndex];
    NSUInteger index = [room.resources indexOfObjectPassingTest:^BOOL(MITMobiusResource *otherResource, NSUInteger idx, BOOL *stop) {
        return [otherResource.identifier isEqualToString:resource.identifier];
    }];

    return index;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResourceWithIdentifier:(NSString*)resourceIdentifier
{
    MITMobiusRoomObject *room = [self.dataSource viewController:self roomAtIndex:self.selectedIndex];
    NSUInteger index = [room.resources indexOfObjectPassingTest:^BOOL(MITMobiusResource *otherResource, NSUInteger idx, BOOL *stop) {
        return [otherResource.identifier isEqualToString:resourceIdentifier];
    }];
    
    return index;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexAfterIndex:(NSUInteger)index
{
    NSInteger nubmerOfResources = [self.dataSource viewController:self numberOfResourcesInRoomAtIndex:self.selectedIndex];
    return (index + 1) % nubmerOfResources;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexBeforeIndex:(NSUInteger)index
{
    NSInteger nubmerOfResources = [self.dataSource viewController:self numberOfResourcesInRoomAtIndex:self.selectedIndex];
    return ((index + nubmerOfResources) - 1) % nubmerOfResources;
}

@end
