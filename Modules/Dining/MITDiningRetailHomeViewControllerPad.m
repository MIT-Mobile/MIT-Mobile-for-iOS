#import "MITDiningRetailHomeViewControllerPad.h"
#import "MITDiningRetailVenueListViewController.h"
#import "MITTiledMapView.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningMapsViewController.h"

@interface MITDiningRetailHomeViewControllerPad () <MKMapViewDelegate, MITDiningRetailVenueListViewControllerDelegate>

@property (nonatomic, strong) MITDiningRetailVenueListViewController *listViewController;
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
    self.mapsViewController = [[MITDiningMapsViewController alloc] initWithNibName:nil bundle:nil];
    self.mapsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mapsViewController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[listView][mapView]|" options:0 metrics:nil views:@{@"mapView": self.mapsViewController.view,
                                                                                                                                      @"listView": self.listViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|" options:0 metrics:nil views:@{@"mapView": self.mapsViewController.view}]];
    [self.mapsViewController updateMapWithDiningPlaces:self.retailVenues];
}

#pragma mark - MITDiningRetailVenueListViewControllerDelegate Methods

- (void)retailVenueListViewController:(MITDiningRetailVenueListViewController *)listViewController didSelectVenue:(MITDiningRetailVenue *)venue
{
    [self.mapsViewController showDetailForRetailVenue:venue];
}

@end
