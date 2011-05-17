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
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
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
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];

    {
        CGRect tableRect = screenFrame;
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
        UILabel *labelView = [[[UILabel alloc] init] autorelease];
        CGRect headerRect = CGRectMake(0, 0, self.tableView.frame.size.width, 96);
        CGSize strSize = [labelText sizeWithFont:labelView.font
                               constrainedToSize:headerRect.size
                                   lineBreakMode:labelView.lineBreakMode];
        headerRect.size.height = strSize.height;
        
        
        UIView *view = [[[UIView alloc] initWithFrame:headerRect] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.autoresizesSubviews = YES;
        
        labelView.frame = headerRect;
        labelView.backgroundColor = [UIColor clearColor];
        labelView.lineBreakMode = UILineBreakModeWordWrap;
        labelView.text = labelText;
        labelView.textAlignment = UITextAlignmentLeft;
        labelView.numberOfLines = 3;

        [view addSubview:labelView];
        self.tableView.tableHeaderView = view;
    }
    
    
    {
        CGRect loadingFrame = screenFrame;
        
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
