#import "FacilitiesUserLocationViewController.h"

#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesRoomViewController.h"
#import "MITLoadingActivityView.h"

static const NSUInteger kMaxResultCount = 10;

@interface FacilitiesUserLocationViewController ()
@property (nonatomic,retain) NSArray* filteredData;
@end

@implementation FacilitiesUserLocationViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize locationManager = _locationManager;
@synthesize filteredData = _filteredData;

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
    }
    return self;
}

- (void)dealloc
{
    self.tableView = nil;
    self.loadingView = nil;
    self.locationManager = nil;
    self.filteredData = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
        NSString *labelText = @"We've narrowed down your location, please choose the closest location below";
        CGRect labelRect = CGRectMake(15, 10, screenFrame.size.width - 30, 200);
        UILabel *labelView = [[[UILabel alloc] initWithFrame:labelRect] autorelease];
        CGSize strSize = [labelText sizeWithFont:labelView.font
                               constrainedToSize:labelRect.size
                                   lineBreakMode:labelView.lineBreakMode];
        labelRect.size.height = strSize.height;
        labelView.frame = labelRect;
        labelView.backgroundColor = [UIColor clearColor];
        labelView.lineBreakMode = UILineBreakModeWordWrap;
        labelView.text = labelText;
        labelView.textAlignment = UITextAlignmentLeft;
        labelView.numberOfLines = 3;
        
        CGRect headerRect = CGRectMake(0, 0, screenFrame.size.width, strSize.height + 10);
        UIView *view = [[[UIView alloc] initWithFrame:headerRect] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.autoresizesSubviews = YES;
        
        [view addSubview:labelView];
        self.tableView.tableHeaderView = view;
    }
    
    
    {
        CGRect loadingFrame = mainView.frame;
        loadingFrame.origin = CGPointZero;
        
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor redColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [self.locationManager startUpdatingLocation];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredData count];
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
    cell.textLabel.text = location.name;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocation *location = nil;
    
    if (tableView == self.tableView) {
        location = (FacilitiesLocation*)[self.filteredData objectAtIndex:indexPath.row];
    }
    
    FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
    controller.location = location;
    
    [self.navigationController pushViewController:controller
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationManager startUpdatingLocation];
    self.locationManager = nil;
    
    switch([error code])
    {
        case kCLErrorDenied:{
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Location Services"
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
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Location Services"
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
    if (self.loadingView) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        self.tableView.hidden = NO;
        [self.view setNeedsDisplay];
    }
    
    self.filteredData = [[FacilitiesLocationData sharedData] locationsWithinRadius:CGFLOAT_MAX
                                                                        ofLocation:newLocation
                                                                      withCategory:nil];
    NSUInteger filterLimit = MIN([self.filteredData count],kMaxResultCount);
    self.filteredData = [self.filteredData objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, filterLimit)]];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
