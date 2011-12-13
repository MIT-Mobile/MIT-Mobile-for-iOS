#import "FacilitiesUserLocationViewController.h"

#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesRoomViewController.h"
#import "MITLoadingActivityView.h"
#import "MITLogging.h"

static const NSUInteger kMaxResultCount = 10;

@interface FacilitiesUserLocationViewController ()
@property (nonatomic,retain) NSArray* filteredData;
@property (nonatomic,retain) CLLocation *currentLocation;
@property (nonatomic,retain) NSTimer *locationTimeout;
- (void)displayTableForCurrentLocation;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)locationUpdateTimedOut;
@end

@implementation FacilitiesUserLocationViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize locationManager = _locationManager;
@synthesize filteredData = _filteredData;
@synthesize currentLocation = _currentLocation;
@synthesize locationTimeout = _locationTimeout;

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Nearby Locations";
        _isLocationUpdating = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopUpdatingLocation];
    self.tableView = nil;
    self.loadingView = nil;
    self.locationManager = nil;
    self.filteredData = nil;
    self.currentLocation = nil;
    self.locationTimeout = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];

    {
        CGRect tableRect = mainView.frame;
        tableRect.origin = CGPointZero;
        
        UITableView *tableView = [[[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped] autorelease];
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
        
    }
    
    {
        CGRect loadingFrame = mainView.frame;
        loadingFrame.origin = CGPointZero;
        
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[FacilitiesLocationData sharedData] addObserver:self
                                           withBlock:^(NSString *name, BOOL dataUpdated, id userData) {
                                               BOOL commandMatch = ([userData isEqualToString:FacilitiesLocationsKey]);
                                               if (commandMatch && dataUpdated) {
                                                   self.filteredData = nil;
                                                   [self displayTableForCurrentLocation];
                                               }
                                           }];
    
    [self startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[FacilitiesLocationData sharedData] removeObserver:self];
    [self stopUpdatingLocation];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self stopUpdatingLocation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private Methods
- (void)displayTableForCurrentLocation {
    if (self.currentLocation == nil) {
        return;
    }
    
    NSMutableArray *locArray = [NSMutableArray arrayWithArray:[[FacilitiesLocationData sharedData] locationsWithinRadius:CGFLOAT_MAX
                                                                                                              ofLocation:self.currentLocation
                                                                                                            withCategory:nil]];
    [locArray removeObjectsInArray:[[FacilitiesLocationData sharedData] hiddenBuildings]];
    self.filteredData = locArray;
    
    if ([self.filteredData count] == 0) {
        return;
    } else {
        
        NSUInteger filterLimit = MIN([self.filteredData count],kMaxResultCount);
        self.filteredData = [self.filteredData objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, filterLimit)]];
        
        if (self.loadingView) {
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
            self.tableView.hidden = NO;
            [self.view setNeedsDisplay];
        }
        
        [self.tableView reloadData];
    }
}

- (void)startUpdatingLocation {
    if (self.locationManager == nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _isLocationUpdating = NO;
    }
    
    if (_isLocationUpdating == NO) {
        [self.locationManager startUpdatingLocation];
        _isLocationUpdating = YES;
    }
}

- (void)stopUpdatingLocation {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        _isLocationUpdating = NO;
        
        [self.locationTimeout invalidate];
        self.locationTimeout = nil;
    }
}

- (void)locationUpdateTimedOut {
    DLog(@"Timeout triggered at accuracy of %f meters", [self.currentLocation horizontalAccuracy]);
    [self displayTableForCurrentLocation];
    [self stopUpdatingLocation];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.filteredData == nil) ? 0 : [self.filteredData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"locationCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    FacilitiesLocation *location = [self.filteredData objectAtIndex:indexPath.row];
    cell.textLabel.text = [location displayString];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocation *location = nil;
    
    if (tableView == self.tableView) {
        location = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
    }
    
    if ([location.isLeased boolValue]) {
        FacilitiesLeasedViewController *controller = [[[FacilitiesLeasedViewController alloc] initWithLocation:location] autorelease];
        
        [self.navigationController pushViewController:controller
                                             animated:YES];
    } else {    
        FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
        controller.location = location;
        
        [self.navigationController pushViewController:controller
                                             animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self stopUpdatingLocation];
    
    ELog(@"%@",[error localizedDescription]);
    
    switch([error code])
    {
        case kCLErrorDenied:{
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to Determine Location"
                                                             message:@"Please turn on location services to allow MIT Mobile to determine your location."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }
            break;
        case kCLErrorNetwork:
        default:
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to Determine Location"
                                                             message:@"Please check your network connection and that you are not in airplane mode."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    CLLocationAccuracy horizontalAccuracy = [newLocation horizontalAccuracy];
    if (horizontalAccuracy < 0) {
        return;
    } else if (([newLocation horizontalAccuracy] > kCLLocationAccuracyHundredMeters) && _isLocationUpdating) {
        if (self.locationTimeout == nil) {
            self.currentLocation = newLocation;
            self.locationTimeout = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                    target:self
                                                                  selector:@selector(locationUpdateTimedOut)
                                                                  userInfo:nil
                                                                   repeats:NO];
        } else if ([self.currentLocation horizontalAccuracy] > horizontalAccuracy) {
            self.currentLocation = newLocation;
        }
        return;
    } else {
        self.currentLocation = newLocation;
        [self stopUpdatingLocation];
    }
    
    [self displayTableForCurrentLocation];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
