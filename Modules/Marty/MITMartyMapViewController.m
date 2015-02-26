#import "MITMartyMapViewController.h"

#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapBrowseContainerViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITLocationManager.h"
#import "MITMartyDetailTableViewController.h"
#import "MITMartyCalloutContentView.h"
#import "MITMartyModel.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";
static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";


@interface MITMartyMapViewController () <MKMapViewDelegate, SMCalloutViewDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MITMartyResource *currentlySelectResource;
@property (nonatomic, strong) MKAnnotationView *resourceAnnotationView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic, strong) MITMartyResource *resource;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;

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
    
    [self setupMapBoundingBoxAnimated:NO];
    
    [self setupCalloutView];
}

- (void)setupCalloutView
{
    SMCalloutView *calloutView = [[SMCalloutView alloc] initWithFrame:CGRectZero];
    calloutView.contentViewMargin = 0;
    calloutView.anchorMargin = 39;
    calloutView.delegate = self;
    calloutView.permittedArrowDirection = SMCalloutArrowDirectionAny;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        calloutView.rightAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
    }
    
    self.calloutView = calloutView;
    
    self.tiledMapView.mapView.calloutView = self.calloutView;
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
    [self setupMapBoundingBoxAnimated:animated];
}

#pragma mark - Map View

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region

    if ([self.resources count]) {
        [self.mapView showAnnotations:self.resources animated:animated];
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
        if ([annotation isKindOfClass:[MITMartyResource class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}

- (void)showCalloutForResource:(MITMartyResource *)resource
{
    for (MITMartyResource *resource2 in self.resources) {
        if ([resource2.identifier caseInsensitiveCompare:resource.identifier] == NSOrderedSame) {
            [self.mapView selectAnnotation:resource2 animated:YES];
        }
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMartyResource class]]) {
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
        [self.calloutView dismissCalloutAnimated:YES];
        self.currentlySelectResource = nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITMartyResource *resource = (MITMartyResource *)view.annotation;
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
    MITMartyResource *resource = (MITMartyResource *)annotationView.annotation;
    
    MITMartyCalloutContentView *contentView = [[MITMartyCalloutContentView alloc] initWithFrame:CGRectZero];
    [contentView configureForResource:resource];
    
    SMCalloutView *calloutView = self.calloutView;
    calloutView.contentView = contentView;
    calloutView.calloutOffset = annotationView.calloutOffset;
    calloutView.rightAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
    
    [calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
    self.calloutView = calloutView;
}

- (void)dismissCurrentCallout
{
    [self.calloutView dismissCalloutAnimated:YES];
}

#pragma mark - Callout View

- (void)presentIPadCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMartyResource *resource = (MITMartyResource *)annotationView.annotation;
    
    self.currentlySelectResource = resource;
    MITMartyDetailTableViewController *detailVC = [[MITMartyDetailTableViewController alloc] init];
    detailVC.resource = resource;
    
    detailVC.view.frame = CGRectMake(0, 0, 320, 500);
    
    SMCalloutView *calloutView = self.calloutView;
    calloutView.contentView = detailVC.view;
    calloutView.contentView.clipsToBounds = YES;
    calloutView.calloutOffset = annotationView.calloutOffset;
    calloutView.rightAccessoryView = nil;
    self.calloutView = calloutView;
    self.calloutViewController = detailVC;
    
    [calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
    
    // We have to adjust the frame of the content view once its in the view hierarchy, because its constraints don't play nicely with SMCalloutView
    detailVC.view.frame = CGRectMake(0, 0, 320, 500);
}

- (void)presentIPhoneCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMartyResource *resource = (MITMartyResource *)annotationView.annotation;
    
    self.currentlySelectResource = resource;
    self.calloutView.title = resource.title;
    self.calloutView.subtitle = resource.subtitle;
    self.calloutView.calloutOffset = annotationView.calloutOffset;
    
    [self.calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
}

#pragma mark - SMCalloutViewDelegate Methods

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset
{
    MKMapView *mapView = self.mapView;
    CGPoint adjustedCenter = CGPointMake(-offset.width + mapView.bounds.size.width * 0.5,
                                         -offset.height + mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [mapView convertPoint:adjustedCenter toCoordinateFromView:mapView];
    [mapView setCenterCoordinate:newCenter animated:YES];
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self pushDetailViewControllerForResource:self.currentlySelectResource];
    } else {
        
        [self presentIPadCalloutForAnnotationView:self.resourceAnnotationView];
    }
}

- (BOOL)calloutViewShouldHighlight:(SMCalloutView *)calloutView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return YES;
    }
    return NO;
}

- (void)pushDetailViewControllerForResource:(MITMartyResource *)resource
{
    MITMartyDetailTableViewController *detailVC = [[MITMartyDetailTableViewController alloc] init];
    detailVC.resource = resource;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}



@end
