#import "MITMobiusMapViewController.h"

#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapBrowseContainerViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITLocationManager.h"
#import "MITMobiusDetailTableViewController.h"
#import "MITMobiusCalloutContentView.h"
#import "MITMartyModel.h"
#import "MITMobiusResourceView.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";
static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";


@interface MITMobiusMapViewController () <MKMapViewDelegate, MITCalloutViewDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MITMobiusResource *currentlySelectResource;
@property (nonatomic, strong) MKAnnotationView *resourceAnnotationView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic, strong) MITMobiusResource *resource;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;

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

- (void)setResources:(NSArray *)resources
{
    [self setResources:resources animated:NO];
}

- (void)setResources:(NSArray *)resources animated:(BOOL)animated
{
    if (![_resources isEqualToArray:resources]) {
        _resources = [[[MITCoreDataController defaultController] mainQueueContext] transferManagedObjects:resources];

        [self _didChangeResources:animated];
    }
}

- (void)_didChangeResources:(BOOL)animated
{
    [self refreshPlaceAnnotations];
    [self recenterOnVisibleResources:animated];
}

#pragma mark - Map View

- (void)recenterOnVisibleResources:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region

    if ([self.resources count]) {
        [self.mapView showAnnotations:self.resources animated:NO];
        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:self.mapEdgeInsets animated:animated];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.resources];
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
        for (MITMobiusResource *resource2 in self.resources) {
            if ([resource2.identifier caseInsensitiveCompare:resource.identifier] == NSOrderedSame) {
                [self.mapView selectAnnotation:resource2 animated:YES];
            }
        }
    } else {
        [self.mapView selectAnnotation:nil animated:YES];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMobiusResource class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        NSInteger placeIndex = [self.resources indexOfObject:annotation];
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
        self.currentlySelectResource = nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITMobiusResource *resource = (MITMobiusResource *)view.annotation;
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
        if (self.resources.count > 0) {
            [self showCalloutForResource:[self.resources firstObject]];
        }
        
        self.showFirstCalloutOnNextMapRegionChange = NO;
    }
}

#pragma mark - Custom Callout

- (void)presentCalloutForMapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView
{
    MITMobiusResource *resource = (MITMobiusResource *)annotationView.annotation;
    
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
    MITMobiusResource *resource = (MITMobiusResource *)annotationView.annotation;
    
    self.currentlySelectResource = resource;
    MITMobiusDetailTableViewController *detailVC = [[MITMobiusDetailTableViewController alloc] init];
    detailVC.resource = resource;
    
    detailVC.view.frame = CGRectMake(0, 0, 320, 500);
    
    self.calloutView.contentView = detailVC.view;
    self.calloutView.contentView.clipsToBounds = YES;
    self.calloutViewController = detailVC;
    
    [self.calloutView presentFromRect:annotationView.bounds inView:annotationView withConstrainingView:self.tiledMapView.mapView];
    
    // We have to adjust the frame of the content view once its in the view hierarchy, because its constraints don't play nicely with SMCalloutView
    detailVC.view.frame = CGRectMake(0, 0, 320, 500);
}

- (void)presentIPhoneCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMobiusResource *resource = (MITMobiusResource *)annotationView.annotation;
    
    self.currentlySelectResource = resource;
    self.calloutView.titleText = resource.title;
    self.calloutView.subtitleText = resource.subtitle;
    
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
        [self pushDetailViewControllerForResource:self.currentlySelectResource];
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
    MITMobiusDetailTableViewController *detailVC = [[MITMobiusDetailTableViewController alloc] init];
    detailVC.resource = resource;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}



@end
