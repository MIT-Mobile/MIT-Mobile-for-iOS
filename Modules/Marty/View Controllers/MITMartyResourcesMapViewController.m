#import "MITMartyResourcesMapViewController.h"
#import "MITMartyModel.h"
#import "MITTiledMapView.h"

@interface MITMartyResourcesMapViewController () <MKMapViewDelegate>
@property(nonatomic,weak) MITTiledMapView *mapView;
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,copy) NSArray *mapAnnotations;

@end

@implementation MITMartyResourcesMapViewController
@synthesize managedObjectContext = _managedObjectContext;


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.autoresizesSubviews = YES;

    MITTiledMapView *mapView = [[MITTiledMapView alloc] init];
    mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    mapView.translatesAutoresizingMaskIntoConstraints = YES;
    [mapView setMapDelegate:self];
    mapView.mapView.region = kMITShuttleDefaultMapRegion;
    mapView.frame = self.view.bounds;

    [self.view addSubview:mapView];
    self.mapView = mapView;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
    }

    return _managedObjectContext;
}



@end
