#import "MITDiningRetailHomeViewControllerPad.h"
#import "MITDiningRetailVenueListViewController.h"
#import "MITTiledMapView.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningMapsViewController.h"

@interface MITDiningRetailHomeViewControllerPad () <MKMapViewDelegate, MITDiningRetailVenueListViewControllerDelegate>

@property (nonatomic, strong) MITDiningRetailVenueListViewController *listViewController;
@property (nonatomic, strong) MITTiledMapView *mapView;
@property (nonatomic, strong) MITDiningMapsViewController *mapsViewController;

@end

@implementation MITDiningRetailHomeViewControllerPad

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
    
    [self setupListViewController];
    [self setupMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    NSLog(@"height: %f", self.view.frame.size.height);
}

- (void)setRetailVenues:(NSArray *)retailVenues
{
    if ([_retailVenues isEqualToArray:retailVenues]) {
        return;
    }
    
    _retailVenues = retailVenues;
    self.listViewController.retailVenues = _retailVenues;
    [self.mapsViewController updateMapWithDiningPlaces:_retailVenues];
}

- (void)setupListViewController
{
    self.listViewController = [[MITDiningRetailVenueListViewController alloc] init];
    self.listViewController.delegate = self;
    self.listViewController.retailVenues = self.retailVenues;
    [self addChildViewController:self.listViewController];
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.listViewController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[listView(==320)]" options:0 metrics:nil views:@{@"listView": self.listViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[listView]-0-|" options:0 metrics:nil views:@{@"listView": self.listViewController.view}]];
}

- (void)setupMapView
{
    /*
    self.mapView = [[MITTiledMapView alloc] initWithFrame:CGRectMake(320, 0, self.view.bounds.size.width - 320, self.view.bounds.size.height)];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
//    self.mapView.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[listView][mapView]|" options:0 metrics:nil views:@{@"mapView": self.mapView,
                                                                                                                                     @"listView": self.listViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|" options:0 metrics:nil views:@{@"mapView": self.mapView}]];
     */
    
    self.mapsViewController = [[MITDiningMapsViewController alloc] initWithNibName:nil bundle:nil];
    self.mapsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mapsViewController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[listView][mapView]|" options:0 metrics:nil views:@{@"mapView": self.mapsViewController.view,
                                                                                                                                      @"listView": self.listViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|" options:0 metrics:nil views:@{@"mapView": self.mapsViewController.view}]];
    [self.mapsViewController updateMapWithDiningPlaces:self.retailVenues];
}

#pragma mark - MKMapViewDelegate Methods

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
//{
//    if ([annotation isKindOfClass:[MITDiningPlace class]]) {
//        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
//        if (!annotationView) {
//            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
//        }
//        [annotationView setNumber:[(MITDiningPlace *)annotation displayNumber]];
//        
//        return annotationView;
//    }
//    return nil;
//}
//
//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
//{
//    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
//        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
//    }
//    return nil;
//}
//
//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
//{
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
//    [tap addTarget:self action:@selector(calloutTapped:)];
//    [view addGestureRecognizer:tap];
//}

#pragma mark - MITDiningRetailVenueListViewControllerDelegate Methods

- (void)retailVenueListViewController:(MITDiningRetailVenueListViewController *)listViewController didSelectVenue:(MITDiningRetailVenue *)venue
{
    [self.mapsViewController showDetailForRetailVenue:venue];
}

@end
