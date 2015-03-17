#import "MITMartyMapViewController.h"

#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapBrowseContainerViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITLocationManager.h"
#import "MITMartyDetailContainerViewController.h"
#import "MITMartyCalloutContentView.h"
#import "MITMartyModel.h"
#import "MITMartyResourceView.h"
#import "MartyMapObject.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";
static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";


@interface MITMartyMapViewController () <MKMapViewDelegate, MITCalloutViewDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MartyMapObject *currentlySelectedRoom;
@property (nonatomic, strong) MKAnnotationView *resourceAnnotationView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic, strong) MITMartyResource *resource;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;


@property(nonatomic,readonly,strong) NSArray *buildingSections;
@property(nonatomic,readonly,strong) NSDictionary *resourcesByBuilding;
@property(nonatomic,strong) NSMutableArray *buildings;


@end

@implementation MITMartyMapViewController

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
    [self setBuildingSections:buildingSections];
    [self setResourcesByBuilding:resourcesByBuilding];
    
    NSMutableArray *buildings = [[NSMutableArray alloc] init];
    
    [buildingSections enumerateObjectsUsingBlock:^(NSString *roomName, NSUInteger idx, BOOL *stop) {
        
        MartyMapObject *mapObject = [[MartyMapObject alloc] initWithEntity:[MartyMapObject entityDescription] insertIntoManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
        mapObject.roomName = roomName;
        
        NSArray *resources = [[[MITCoreDataController defaultController] mainQueueContext] transferManagedObjects:resourcesByBuilding[roomName]];
        mapObject.resources = [NSOrderedSet orderedSetWithArray:resources];
        MITMartyResource *resource = [mapObject.resources firstObject];
        
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
        if ([annotation isKindOfClass:[MITMartyResource class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    
    [self.mapView removeAnnotations:annotationsToRemove];
}

- (void)showCalloutForResource:(MITMartyResource *)resource
{
    if (resource) {
     
        [self.buildings enumerateObjectsUsingBlock:^(MartyMapObject *mapObject, NSUInteger idx, BOOL *stop) {
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
    if ([annotation isKindOfClass:[MartyMapObject class]]) {
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
        
        MartyMapObject *mapObject = (MartyMapObject *)view.annotation;
        MITMartyResource *resource = [mapObject.resources firstObject];
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
    
    MartyMapObject *mapObject = (MartyMapObject *)annotationView.annotation;
    MITMartyResource *resource = [mapObject.resources firstObject];
    
    MITMartyCalloutContentView *contentView = [[MITMartyCalloutContentView alloc] init];
    contentView.resourceView.backgroundColor = [UIColor clearColor];
    contentView.resourceView.machineName = resource.name;
    contentView.resourceView.location = resource.room;
    [contentView.resourceView setStatus:MITMartyResourceStatusOnline withText:resource.status];
    
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
    MartyMapObject *mapObject = (MartyMapObject *)annotationView.annotation;
    MITMartyResource *resource = [mapObject.resources firstObject];
    
    self.currentlySelectedRoom = mapObject;
    MITMartyDetailContainerViewController *detailContainerViewController = [[MITMartyDetailContainerViewController alloc] initWithResource:resource resources:self.resourcesByBuilding[resource.room] nibName:nil bundle:nil];

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
    MartyMapObject *mapObject = (MartyMapObject *)annotationView.annotation;
    MITMartyResource *resource = [mapObject.resources firstObject];
    
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
        
        MartyMapObject *mapObject = self.currentlySelectedRoom;
        MITMartyResource *resource = [mapObject.resources firstObject];
        
        [self pushDetailViewControllerForResource:resource];
    } else {
        
        [self presentIPadCalloutForAnnotationView:self.resourceAnnotationView];
    }
}

- (void)calloutViewRemovedFromViewHierarchy:(MITCalloutView *)calloutView
{
    /* Do Nothing */
}

- (void)pushDetailViewControllerForResource:(MITMartyResource *)resource
{
    MITMartyDetailContainerViewController *detailContainerViewController = [[MITMartyDetailContainerViewController alloc] initWithResource:resource resources:self.resourcesByBuilding[resource.room] nibName:nil bundle:nil];
    [self.navigationController pushViewController:detailContainerViewController animated:YES];
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}



@end
