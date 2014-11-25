#import "MITDiningMapsViewController.h"
#import "MITTiledMapView.h"
#import "MITDiningPlace.h"
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningRetailVenueDetailViewController.h"
#import "MITDiningHouseVenueDetailViewController.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";

static NSString * const kMITEntityNameDiningHouseVenue = @"MITDiningHouseVenue";
static NSString * const kMITEntityNameDiningRetailVenue = @"MITDiningRetailVenue";

@interface MITDiningMapsViewController () <NSFetchedResultsControllerDelegate, MKMapViewDelegate, MITDiningRetailVenueDetailViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, readonly) MKMapView *mapView;
@property (strong, nonatomic) NSArray *places;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (nonatomic, copy) NSString *currentlyDisplayedEntityName;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic, strong) MKAnnotationView *annotationViewForPopoverAfterRegionChange;

@end

@implementation MITDiningMapsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupTiledMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MapView Methods

- (void)setupTiledMapView
{
    [self.tiledMapView setLeftButtonHidden:NO animated:NO];
    [self.tiledMapView setRightButtonHidden:YES animated:NO];
    //self.mapView.delegate = self;
    [self.tiledMapView setMapDelegate:self];
    self.mapView.showsUserLocation = YES;
    [self setupMapBoundingBoxAnimated:NO];
}

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    if ([self.places count] > 0) {
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in self.places)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        double inset = -zoomRect.size.width * 0.1;
        [self.mapView setVisibleMapRect:MKMapRectInset(zoomRect, inset, inset) animated:YES];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

#pragma mark - Places

- (void)setPlaces:(NSArray *)places
{
    [self setPlaces:places animated:NO];
}

- (void)setPlaces:(NSArray *)places animated:(BOOL)animated
{
    _places = places;
    [self refreshPlaceAnnotations];
    [self setupMapBoundingBoxAnimated:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    [self setPlaces:nil animated:animated];
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.places];
}

- (void)removeAllPlaceAnnotations
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITDiningPlace class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITDiningPlace class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        [annotationView setNumber:[(MITDiningPlace *)annotation displayNumber]];
        
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
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self showDetailForAnnotationView:view];
        [self.mapView deselectAnnotation:view.annotation animated:NO];
    } else {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [tap addTarget:self action:@selector(calloutTapped:)];
        [view addGestureRecognizer:tap];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:gestureRecognizer];
    }
}

- (void)calloutTapped:(UITapGestureRecognizer *)tap
{
    [self showDetailForAnnotationView:(MKAnnotationView *)tap.view];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self showDetailForAnnotationView:view];
}

- (void)showDetailForAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITDiningPlace *place = view.annotation;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            if (place.retailVenue) {
                // Scroll map so that the annotation is centered vertically, and on the right edge horizontally
                // This ensures that the popover will not cover the left list
                MKCoordinateRegion newMapRegion = self.mapView.region;
                CLLocationCoordinate2D newMapRegionCenter = newMapRegion.center;
                newMapRegionCenter.latitude = place.coordinate.latitude;
                newMapRegionCenter.longitude = place.coordinate.longitude - (0.4 * newMapRegion.span.longitudeDelta);
                newMapRegion.center = newMapRegionCenter;
                
                // The map region is not exact when set. The new region can be within a margin of error and the regionDidChange delegate call will never be called.
                // Have to check within this margin to make sure we show the popover if the map is already scrolled to the right spot. This seems right based on testing, there is no official answer.
                if (newMapRegion.center.latitude > self.mapView.region.center.latitude - 0.00000001 && newMapRegion.center.latitude < self.mapView.region.center.latitude + 0.00000001 &&
                    newMapRegion.center.longitude > self.mapView.region.center.longitude - 0.00000001 && newMapRegion.center.longitude < self.mapView.region.center.longitude + 0.00000001) {
                    [self showRetailPopoverForAnnotationView:view];
                } else {
                    self.annotationViewForPopoverAfterRegionChange = view;
                    [self.mapView setRegion:newMapRegion animated:YES];
                }
            }
        } else {
            if (place.houseVenue) {
                MITDiningHouseVenueDetailViewController *detailVC = [[MITDiningHouseVenueDetailViewController alloc] init];
                detailVC.houseVenue = place.houseVenue;
                [self.navigationController pushViewController:detailVC animated:YES];
            } else if (place.retailVenue) {
                MITDiningRetailVenueDetailViewController *detailVC = [[MITDiningRetailVenueDetailViewController alloc] initWithNibName:nil bundle:nil];
                detailVC.retailVenue = place.retailVenue;
                [self.navigationController pushViewController:detailVC animated:YES];
            }
        }
    }
}

- (void)showDetailForRetailVenue:(MITDiningRetailVenue *)retailVenue
{
    for (MITDiningPlace *place in self.places) {
        if ([place.retailVenue.identifier isEqualToString:retailVenue.identifier]) {
            [self.mapView selectAnnotation:place animated:YES];
            return;
        }
    }
    
    // If we get here, the place doesn't have an annotation (probably because it has missing/invalid location data)
    [self showRetailPopoverForVenueWithoutAnnotation:retailVenue];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.shouldRefreshAnnotationsOnNextMapRegionChange) {
        [self refreshPlaceAnnotations];
        self.shouldRefreshAnnotationsOnNextMapRegionChange = NO;
    } else if (self.annotationViewForPopoverAfterRegionChange) {
        MITDiningPlace *place = self.annotationViewForPopoverAfterRegionChange.annotation;
        if (place.retailVenue) {
            [self showRetailPopoverForAnnotationView:self.annotationViewForPopoverAfterRegionChange];
        }
        self.annotationViewForPopoverAfterRegionChange = nil;
    }
}

- (void)showRetailPopoverForAnnotationView:(MKAnnotationView *)view
{
    MITDiningPlace *place = view.annotation;
    MITDiningRetailVenueDetailViewController *detailVC = [[MITDiningRetailVenueDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.retailVenue = place.retailVenue;
    detailVC.delegate = self;
    self.detailPopoverController = [[UIPopoverController alloc] initWithContentViewController:detailVC];
    
    CGFloat tableHeight = [detailVC targetTableViewHeight];
    CGFloat minPopoverHeight = [self minPopoverHeight];
    CGFloat maxPopoverHeight = [self maxPopoverHeight];
    
    if (tableHeight > maxPopoverHeight) {
        tableHeight = maxPopoverHeight;
    } else if (tableHeight < minPopoverHeight) {
        tableHeight = minPopoverHeight;
    }
    
    [self.detailPopoverController setPopoverContentSize:CGSizeMake(320, tableHeight) animated:NO];
    
    [self.detailPopoverController presentPopoverFromRect:view.frame inView:self.mapView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showRetailPopoverForVenueWithoutAnnotation:(MITDiningRetailVenue *)retailVenue
{
    MITDiningRetailVenueDetailViewController *detailVC = [[MITDiningRetailVenueDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.retailVenue = retailVenue;
    detailVC.delegate = self;
    self.detailPopoverController = [[UIPopoverController alloc] initWithContentViewController:detailVC];
    
    CGFloat tableHeight = [detailVC targetTableViewHeight];
    CGFloat minPopoverHeight = [self minPopoverHeight];
    CGFloat maxPopoverHeight = [self maxPopoverHeight];
    
    if (tableHeight > maxPopoverHeight) {
        tableHeight = maxPopoverHeight;
    } else if (tableHeight < minPopoverHeight) {
        tableHeight = minPopoverHeight;
    }
    
    [self.detailPopoverController setPopoverContentSize:CGSizeMake(320, tableHeight) animated:NO];
    
    CLLocationCoordinate2D presentationCoordinate = CLLocationCoordinate2DMake(self.mapView.region.center.latitude, self.mapView.region.center.longitude + (0.4 * self.mapView.region.span.longitudeDelta));
    CGPoint presentationPoint = [self.mapView convertCoordinate:presentationCoordinate toPointToView:self.mapView];
    // TODO: Move the popover presentation point to the left to account for the missing arrow. Need to use our custom popover bg view class because simply moving this point doesnt work with permittedArrowDirections:0
    CGRect presentationRectInMapView = CGRectMake(presentationPoint.x, presentationPoint.y, 10, 10);
    [self.detailPopoverController presentPopoverFromRect:presentationRectInMapView inView:self.mapView permittedArrowDirections:0 animated:YES];
}

#pragma mark - Loading Events Into Map

- (void)updateMapWithDiningPlaces:(NSArray *)diningPlaceArray
{
    [self removeAllPlaceAnnotations];
    NSMutableArray *annotationsToAdd = [NSMutableArray array];
    for (int i = 0; i < diningPlaceArray.count; i++) {
        
        id venue = diningPlaceArray[i];
        MITDiningPlace *diningPlace = nil;
        if ([venue isKindOfClass:[MITDiningRetailVenue class]]) {
            diningPlace = [[MITDiningPlace alloc] initWithRetailVenue:venue];
        } else if ([venue isKindOfClass:[MITDiningHouseVenue class]]) {
            diningPlace = [[MITDiningPlace alloc] initWithHouseVenue:venue];
        }
        if (diningPlace) {
            diningPlace.displayNumber = (i + 1);
            [annotationsToAdd addObject:diningPlace];
        }
    }
    
    self.places = annotationsToAdd;
}

#pragma mark - MapView Getter

- (MKMapView *)mapView
{
    return self.tiledMapView.mapView;
}

#pragma mark - MITDiningRetailVenueDetailViewControllerDelegate Methods

- (void)retailDetailViewControllerDidUpdateSize:(MITDiningRetailVenueDetailViewController *)retailDetailViewController
{
    CGFloat tableHeight = [retailDetailViewController targetTableViewHeight];
    CGFloat maxPopoverHeight = [self maxPopoverHeight];
    CGFloat minPopoverHeight = [self minPopoverHeight];
    
    if (tableHeight > maxPopoverHeight) {
        tableHeight = maxPopoverHeight;
    } else if (tableHeight < minPopoverHeight) {
        tableHeight = minPopoverHeight;
    }
    
    [self.detailPopoverController setPopoverContentSize:CGSizeMake(320, tableHeight) animated:YES];
}

- (void)retailDetailViewController:(MITDiningRetailVenueDetailViewController *)viewController didUpdateFavoriteStatusForVenue:(MITDiningRetailVenue *)venue
{
    if ([self.delegate respondsToSelector:@selector(popoverChangedFavoriteStatusForRetailVenue:)]) {
        [self.delegate popoverChangedFavoriteStatusForRetailVenue:venue];
    }
}

#pragma mark - UIPopover Calculations

- (CGFloat)maxPopoverHeight
{
    CGFloat navbarHeight = 44;
    CGFloat statusBarHeight = 20;
    CGFloat toolbarHeight = 44;
    CGFloat padding = 30;
    CGFloat maxPopoverHeight = self.view.bounds.size.height - navbarHeight - statusBarHeight - toolbarHeight - (2 * padding);
    return maxPopoverHeight;
}

- (CGFloat)minPopoverHeight
{
    return 360.0;
}

@end
