#import "MITToursMapViewController.h"
#import "MITToursStop.h"
#import "MITTiledMapView.h"

@interface MITToursMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;

@property (nonatomic, strong, readwrite) MITToursTour *tour;

@end

@implementation MITToursMapViewController

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tour = tour;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTiledMapView];
}

- (void)setupTiledMapView
{
    [self.tiledMapView setMapDelegate:self];
    [self.tiledMapView setButtonsHidden:YES animated:NO];
    
    MKMapView *mapView = self.tiledMapView.mapView;
    mapView.showsUserLocation = YES;
    
    // Set up annotations from stops
    for (MITToursStop *stop in self.tour.stops) {
        NSLog(@"stop ID %@", stop.identifier);
    }
}

#pragma mark - MKMapViewDelegate Methods

@end
