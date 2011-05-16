//
//  FacilitiesUserLocation.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/4/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "FacilitiesUserLocationViewController.h"

#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
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
    return [self initWithNibName:@"FacilitiesUserLocation"
                          bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

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
    
    self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
    [self.view insertSubview:self.loadingView
                aboveSubview:self.tableView];
    
    CGRect headerRect = CGRectMake(0, 0, self.tableView.frame.size.width, 96);
    UIView *view = [[[UIView alloc] initWithFrame:headerRect] autorelease];
    UILabel *labelView = [[[UILabel alloc] initWithFrame:headerRect] autorelease];
    
    labelView.backgroundColor = [UIColor clearColor];
    labelView.lineBreakMode = UILineBreakModeWordWrap;
    labelView.text = @"We've narrowed down your location, please choose the closest location below:";
    labelView.textAlignment = UITextAlignmentLeft;
    
    [view addSubview:labelView];
    
    self.tableView.tableHeaderView = view;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource
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

#pragma mark -
#pragma mark UITableViewDelegate


#pragma mark -
#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationManager startUpdatingLocation];
    self.locationManager = nil;
    
    switch([error code])
    {
        case kCLErrorNetwork:
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Please check your network connection or that you are not in airplane mode"
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Turn on location services to allow \"MIT Mobile\" to determine your location"
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }
            break;
        default:
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Unknown network error"
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
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
