#import "FacilitiesUserLocationViewController.h"

#import "MITBuildingServicesReportForm.h"

#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesRoomViewController.h"
#import "MITLoadingActivityView.h"
#import "MITLogging.h"
#import "MITAdditions.h"

static const NSUInteger kMaxResultCount = 10;

@interface FacilitiesUserLocationViewController ()
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLLocation *currentLocation;
@property (nonatomic,strong) NSTimer *locationTimer;

@property (nonatomic,weak) MITLoadingActivityView* loadingView;
@property (nonatomic,weak) id dataObserverToken;

@property (nonatomic,copy) NSArray* filteredData;
@property (nonatomic,getter = isUpdatingCurrentLocation) BOOL updatingCurrentLocation;

- (void)displayTableForCurrentLocation;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
@end

@implementation FacilitiesUserLocationViewController
- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Nearby Locations";
        self.updatingCurrentLocation = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopUpdatingLocation];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[UIView alloc] initWithFrame:screenFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;

    mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        mainView.backgroundColor = [UIColor mit_backgroundColor];
    }

    {
        CGRect tableRect = mainView.frame;
        tableRect.origin = CGPointZero;
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableRect
                                                              style:UITableViewStyleGrouped];
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
        
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
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
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.dataObserverToken) {
        self.dataObserverToken = [[FacilitiesLocationData sharedData] addUpdateObserver:^(NSString *name, BOOL dataUpdated, id userData) {
            BOOL commandMatch = ([userData isEqualToString:FacilitiesLocationsKey]);
            if (commandMatch && dataUpdated) {
                self.filteredData = nil;
                [self displayTableForCurrentLocation];
            }
        }];
    }
    
    [self startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dataObserverToken) {
        [[FacilitiesLocationData sharedData] removeUpdateObserver:self.dataObserverToken];
    }
    
    [self stopUpdatingLocation];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self stopUpdatingLocation];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private Methods
- (void)displayTableForCurrentLocation {
    if (self.currentLocation) {
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
                self.tableView.hidden = NO;
                [self.view setNeedsDisplay];
            }
            
            [self.tableView reloadData];
        }
    }
}

- (void)startUpdatingLocation {
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.updatingCurrentLocation = NO;
    }
    
    if (self.isUpdatingCurrentLocation == NO) {
        [self.locationManager startUpdatingLocation];
        self.updatingCurrentLocation = YES;
    }
}

- (void)stopUpdatingLocation {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        self.updatingCurrentLocation = NO;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"locationCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    FacilitiesLocation *location = [self.filteredData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [location displayString];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocation *location = nil;
    
    if (tableView == self.tableView)
    {
        location = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
    }
    
    [[MITBuildingServicesReportForm sharedServiceReport] setLocation:location shouldSetRoom:![location.isLeased boolValue]];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:MITBuildingServicesLocationChosenNoticiation object:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self stopUpdatingLocation];
    
    DDLogError(@"%@",[error localizedDescription]);
    
    switch([error code]) {
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Determine Location"
                                                             message:@"Please turn on location services to allow Tim Info to determine your location."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            [alert show];
        }
            break;
        case kCLErrorNetwork:
        default:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Determine Location"
                                                             message:@"Please check your network connection and that you are not in airplane mode."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
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
    } else if ((horizontalAccuracy > kCLLocationAccuracyHundredMeters) && self.isUpdatingCurrentLocation) {
        if (self.locationTimer == nil) {
            self.currentLocation = newLocation;
            
            __weak FacilitiesUserLocationViewController *weakSelf = self;
            self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                 repeats:NO
                                                                   fired:^{
                                                                       DDLogVerbose(@"Timeout triggered at accuracy of %f meters", [weakSelf.currentLocation horizontalAccuracy]);
                                                                       [weakSelf displayTableForCurrentLocation];
                                                                       [weakSelf stopUpdatingLocation];
                                                                       weakSelf.locationTimer = nil;
                                                                   }];

        } else if ([self.currentLocation horizontalAccuracy] > horizontalAccuracy) {
            self.currentLocation = newLocation;
        }
    } else {
        self.currentLocation = newLocation;
        [self stopUpdatingLocation];
        [self displayTableForCurrentLocation];
    }
    
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
