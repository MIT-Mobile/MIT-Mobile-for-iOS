#import "TourOverviewViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "TourSiteOrRoute.h"
#import "MITThumbnailView.h"
#import "SiteDetailViewController.h"
#import "CoreDataManager.h"
#import "TourSiteMapAnnotation.h"
#import "CampusTourSideTrip.h"
#import "StartingLocationViewController.h"
#import "CoreLocation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface TourOverviewViewController (Private)

- (void)requestImageForSite:(TourSiteOrRoute *)site;
- (NSString *)distanceTextForSite:(TourSiteOrRoute *)site;
- (NSString *)textForDistance:(CLLocationDistance)meters;
- (void)selectAnnotationClosestTo:(CLLocation *)location;
- (void)showStartSuggestions:(id)sender;

- (void)setupNotSureScrim;
- (void)setupMapLegend;

@end


#define METERS_PER_FOOT 0.3048
#define FEET_PER_MILE 5280
#define METERS_PER_SMOOT 1.7018

#define TOUR_SITE_ROW_HEIGHT 80

enum {
    MapListSegmentMap = 0,
    MapListSegmentList,
};

@implementation TourOverviewViewController

@synthesize mapView = _mapView, tableView = _tableView, callingViewController, sites = _sites, userLocation = _userLocation, selectedAnnotation;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)viewWillAppear:(BOOL)animated {
    [self.mapView addTileOverlay];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.mapView removeTileOverlay];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    

    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationItem.title = @"Tour Overview";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                   style:UIBarButtonItemStyleBordered
                                                                                  target:self
                                                                                  action:@selector(dismiss:)] autorelease];
        self.sites = ((SiteDetailViewController *)callingViewController).sites;
    } else {
        self.navigationItem.title = @"Starting Point";
        self.sites = [[ToursDataManager sharedManager] allSitesForTour];
    }
    
    locateUserButton.image = [UIImage imageNamed:@"map/map_button_location.png"];
    leftSideFixedSpace.width = locateUserButton.image.size.width + 22;
    
    [self showMap:YES];
}

- (void)dismiss:(id)sender {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)selectionDidComplete {
    [self hideCoverView];
    
    // if we called from a side trip
    if (callingViewController.navigationController.visibleViewController != callingViewController) {
        [callingViewController.navigationController popViewControllerAnimated:NO];
    }
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)orientationChanged:(NSNotification *)notification {
    // if we push a view controller onto list mode, we will continue to receive notifications
    if (self.navigationController.visibleViewController != self)
        return;
    
    UIDevice *device = [notification object];
    
    if (UIDeviceOrientationIsPortrait(device.orientation)) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [UIView beginAnimations:@"hideCover" context:nil];
        [UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hideCoverView)];
        coverView.alpha = 0;
        [UIView commitAnimations];
        
    } else {
        // coverflow
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        CGRect frame = CGRectMake(0, 0, window.frame.size.height, window.frame.size.width); // make horizontal
        if (coverView == nil) {
            coverView = [[FlowCoverView alloc] initWithFrame:frame];
            coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            coverView.delegate = self;
            coverView.backgroundColor = [UIColor whiteColor];
        }
        
        // label for site title
        CGRect labelFrame = CGRectMake(frame.size.width / 2 - 100, frame.size.height - 44, 200, 22);
        UILabel *label = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        label.font = [UIFont systemFontOfSize:14];
        label.tag = 7283;
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [coverView addSubview:label];
        
        if (device.orientation == UIInterfaceOrientationLandscapeRight) {
            coverView.layer.anchorPoint = CGPointMake((frame.size.height / 2) / window.frame.size.height,
                                                      1 - (frame.size.width / 2) / window.frame.size.width);
            coverView.transform = CGAffineTransformMakeRotation(M_PI_2);
            
        } else { // UIInterfaceOrientationLandscapeLeft
            coverView.layer.anchorPoint = CGPointMake(1 - (frame.size.height / 2) / window.frame.size.height,
                                                      (frame.size.width / 2) / window.frame.size.width);
            coverView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }

        coverView.alpha = 0;
        [window addSubview:coverView];

		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [UIView beginAnimations:@"showCover" context:nil];
        [UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
        coverView.alpha = 1;
        [UIView commitAnimations];
    }
    
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    self.mapView.delegate = nil;
    self.userLocation = nil;
    self.selectedAnnotation = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.mapView = nil;
}


- (void)dealloc {
    [self.mapView removeTileOverlay];
    self.mapView.delegate = nil;
    self.mapView = nil;
    [self hideCoverView]; // also releases coverview
    self.sites = nil;
    self.userLocation = nil;
    self.callingViewController = nil;
    self.selectedAnnotation = nil;
    
    [super dealloc];
}

#pragma mark User actions

- (IBAction)locateUserPressed:(id)sender {
    if (self.userLocation) {
        CLLocationCoordinate2D center = self.userLocation.coordinate;
        self.mapView.region = MKCoordinateRegionMake(center, DEFAULT_MAP_SPAN);
    }
    
    // TODO: maybe use mapView.stayCenteredOnUserLocation to track users as they move
    //locateUserButton.style = self.mapView.showsUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
}

- (IBAction)mapListToggled:(id)sender {
    switch (mapListToggle.selectedSegmentIndex) {
        case MapListSegmentMap:
            [self showMap:YES];
            break;
        case MapListSegmentList:
            [self showMap:NO];
            break;
        default:
            break;
    }
}

- (void)showStartSuggestions:(id)sender {
    StartingLocationViewController *vc = [[[StartingLocationViewController alloc] init] autorelease];
    vc.startingLocations = [[ToursDataManager sharedManager] startLocationsForTour];
    vc.overviewController = self;
    UINavigationController *dummyVC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] presentAppModalViewController:dummyVC animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        SiteDetailViewController *siteDetailVC = (SiteDetailViewController *)callingViewController;
        [siteDetailVC jumpToSite:selectedSiteIndex];
        
        [self selectionDidComplete];
    }
}

- (void)showMap:(BOOL)showMap {
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width,
                              self.view.frame.size.height - toolBar.frame.size.height);
    
    NSMutableArray *toolbarItems = [toolBar.items mutableCopy];
    
    if (showMap) {
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        
        [self.tableView removeFromSuperview];
        if (!self.mapView) {
            self.mapView = [[[MITMapView alloc] initWithFrame:frame] autorelease];
            self.mapView.delegate = self;
            self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            MITGenericMapRoute *mapRoute = [[ToursDataManager sharedManager] mapRouteForTour];
            self.mapView.region = [self.mapView regionForRoute:mapRoute];
            [self.mapView addRoute:mapRoute];
            
            for (TourSiteOrRoute *aSite in self.sites) {
                TourSiteMapAnnotation *annotation = [[[TourSiteMapAnnotation alloc] init] autorelease];
                if (self.userLocation != nil) {
                    annotation.subtitle = [self distanceTextForSite:aSite];
                }
                annotation.site = aSite;
                [self.mapView addAnnotation:annotation];
                
                if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
                    if (aSite == ((SiteDetailViewController *)callingViewController).siteOrRoute
                        || aSite == ((SiteDetailViewController *)callingViewController).siteOrRoute.nextComponent)
                    {
                        [self.mapView selectAnnotation:selectedAnnotation animated:YES withRecenter:YES];
                        self.selectedAnnotation = annotation; // attempt select again after annotation views are populated
                    }
                }
            }
            
            self.mapView.showsUserLocation = YES;
        }
        [self.view addSubview:self.mapView];
        
        if (![toolbarItems containsObject:leftSideFixedSpace]) {
            [toolbarItems insertObject:leftSideFixedSpace atIndex:0];
        }
        if (![toolbarItems containsObject:locateUserButton]) {
            [toolbarItems addObject:locateUserButton];
        }
        
    } else {
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        [self.mapView removeFromSuperview];
        if (!self.tableView) {
            self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
            self.tableView.rowHeight = TOUR_SITE_ROW_HEIGHT;
            self.tableView.delegate = self;
            self.tableView.dataSource = self;
            self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        [self.view addSubview:self.tableView];
        
        if ([toolbarItems containsObject:locateUserButton]) {
            [toolbarItems removeObject:locateUserButton];
        }
        if ([toolbarItems containsObject:leftSideFixedSpace]) {
            [toolbarItems removeObject:leftSideFixedSpace];
        }
    }
    
    displayingMap = showMap;
    
    [toolBar setItems:toolbarItems animated:NO];
    [toolbarItems release];

    if (displayingMap) {
        if (![callingViewController isKindOfClass:[SiteDetailViewController class]]) {
            [self setupNotSureScrim];
        } else {
            [self setupMapLegend];
        }
    }
    
}

- (void)setupMapLegend {
    UIView *legend = [self.view viewWithTag:102];
    if (!legend) {
        CGFloat legendHeight  = 33;
        CGFloat markerSpacing = -3; // space between marker and label -- compensates for markers' built-in padding 
        CGFloat keySpacing    = 11; // space between legend items
        CGFloat keyPadding    =  6; // space to the left of first marker
        UIFont *labelFont = [UIFont systemFontOfSize:13];
        
        NSArray *images = [NSArray arrayWithObjects:
                           [ToursDataManager imageForVisitStatus:TourSiteVisiting],
                           [ToursDataManager imageForVisitStatus:TourSiteVisited],
                           [ToursDataManager imageForVisitStatus:TourSiteNotVisited], nil];
        
        NSArray *labels = [NSArray arrayWithObjects:
                           [ToursDataManager labelForVisitStatus:TourSiteVisiting],
                           [ToursDataManager labelForVisitStatus:TourSiteVisited],
                           [ToursDataManager labelForVisitStatus:TourSiteNotVisited], nil];
        
        legend = [[[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - toolBar.frame.size.height - legendHeight,
                                                           self.view.frame.size.width, legendHeight)] autorelease];
        legend.backgroundColor = [UIColor clearColor];
        legend.layer.cornerRadius = 5.0;
        legend.tag = 102;
        legend.userInteractionEnabled = NO;
        legend.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        UIImage *backgroundImage = [UIImage imageNamed:@"tours/map-legend-overlay.png"];
        UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]] autorelease];
        backgroundView.frame = CGRectMake(0, -4, legend.frame.size.width, legend.frame.size.height + 4); // compensate for transparent pixels
        [legend addSubview:backgroundView];
        
        CGRect frame = CGRectZero;
        frame.origin.x = keyPadding;
        for (NSInteger i = 0; i < images.count; i++) {
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:[images objectAtIndex:i]] autorelease];
            frame.size = imageView.frame.size;
            imageView.frame = frame;
            [legend addSubview:imageView];
            
            frame.origin.x += imageView.frame.size.width + markerSpacing;
            NSString *labelText = [labels objectAtIndex:i];
            CGSize labelSize = [labelText sizeWithFont:labelFont];
            frame.size.width = labelSize.width;
            
            UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.text = labelText;
            label.font = labelFont;
            [legend addSubview:label];
            
            frame.origin.x += label.frame.size.width + keySpacing;
        }
    }

    // resize map view so google logo shows
    CGRect frame = self.mapView.frame;
    frame.size.height -= legend.frame.size.height;
    self.mapView.frame = frame;
    
    [legend retain];
    [legend removeFromSuperview];
    [self.view addSubview:legend];
    [legend release];
    
}

- (void)setupNotSureScrim {
    UIControl *control = (UIControl *)[self.view viewWithTag:777];
    if (!control) {
        UIImage *scrim = [UIImage imageNamed:@"tours/tour_notsure_scrim_top.png"];
        
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, scrim.size.height);
        
        control = [[[UIControl alloc] initWithFrame:frame] autorelease];
        control.backgroundColor = [UIColor clearColor];
        control.tag = 777;
        
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:scrim] autorelease];
        [control addSubview:imageView];
        
        frame.origin.x += 7;
        frame.origin.y += 2;
        frame.size.width -= 14;
        frame.size.height = 21;
        
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.text = @"Not sure where to begin?";
        label.font = [UIFont boldSystemFontOfSize:15];
        label.textColor = [UIColor colorWithHexString:@"#202020"];
        label.backgroundColor = [UIColor clearColor];
        label.userInteractionEnabled = NO;
        
        frame.origin.y += 17;
        
        UILabel *anotherLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        anotherLabel.text = @"Browse suggested starting points.";
        anotherLabel.font = [UIFont systemFontOfSize:15];
        anotherLabel.textColor = [UIColor colorWithHexString:@"#404040"];
        anotherLabel.backgroundColor = [UIColor clearColor];
        anotherLabel.userInteractionEnabled = NO;
        
        [control addSubview:label];
        [control addSubview:anotherLabel];
        [control addTarget:self action:@selector(showStartSuggestions:) forControlEvents:UIControlEventTouchUpInside];
		
		UIImageView *chevronView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow.png"]] autorelease];
		chevronView.center = CGPointMake(control.frame.size.width - 10, (round(control.frame.size.height / 2)-2));
		chevronView.userInteractionEnabled = NO;
		[control addSubview:chevronView];
    }
    
    [control retain];
    [control removeFromSuperview];
    [self.view addSubview:control];
    [control release];
}

- (void)selectTourSite:(TourSiteOrRoute *)site {
    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        SiteDetailViewController *siteDetailVC = (SiteDetailViewController *)callingViewController;
        
        if (siteDetailVC.showingConclusionScreen && siteDetailVC.siteOrRoute == site) {
            [siteDetailVC previousButtonPressed:nil];
            [self dismiss:nil];
        }
        else if (siteDetailVC.siteOrRoute == site || siteDetailVC.siteOrRoute.nextComponent == site) {
            // user selected current stop, so just show then what they were looking at before
            [self dismiss:nil];
        }
        else if (siteDetailVC.siteOrRoute.nextComponent.nextComponent == site && siteDetailVC.firstSite != site) {
            // user selected next stop; show directions to it
            [siteDetailVC nextButtonPressed:nil];
            [self selectionDidComplete];
        }
        else {
            // user is skipping ahead or going back
            selectedSiteIndex = [siteDetailVC.sites indexOfObject:site];
            if (selectedSiteIndex == NSNotFound) {
                for (TourSiteOrRoute *aSite in siteDetailVC.sites) {
                    selectedSiteIndex++;
                    if ([aSite.componentID isEqualToString:site.componentID]) {
                        break;
                    }
                }
            }
            NSInteger currentSiteIndex;
            // TODO: make this work for not-on-tour starting locations after we insert the start locations screen
            if ([siteDetailVC.siteOrRoute.type isEqualToString:@"site"]) {
                currentSiteIndex = [siteDetailVC.sites indexOfObject:siteDetailVC.siteOrRoute];
            } else {
                TourSiteOrRoute *currentSite = siteDetailVC.siteOrRoute.nextComponent;
                currentSiteIndex = [siteDetailVC.sites indexOfObject:currentSite];
            }
            NSInteger difference = selectedSiteIndex - currentSiteIndex;
            NSString *message;
            if (difference < 0) {
                message = [NSString stringWithFormat:@"Are you sure you want to go back %d stops?", -difference];
            } else {
                message = [NSString stringWithFormat:@"Are you sure you want to skip ahead %d stops?", difference];
            }
            
            NSString *title = [NSString string];
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                       otherButtonTitles:@"OK", nil] autorelease];
            alertView.tag = 14;
            [alertView show];
        }
        
    } else {
        SiteDetailViewController *detailVC = [[[SiteDetailViewController alloc] init] autorelease];
        detailVC.siteOrRoute = site;
        detailVC.firstSite = site;
        [self hideCoverView];
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sites.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* CellIdentifier = @"Cell";

    TourOverviewTableViewCell *cell = (TourOverviewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[TourOverviewTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.site = [self.sites objectAtIndex:indexPath.row];
    if (self.userLocation) {
        cell.detailTextLabel.text = [self distanceTextForSite:cell.site];
    }
    
    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        SiteDetailViewController *detailVC = (SiteDetailViewController *)callingViewController;
        TourSiteOrRoute *component = detailVC.siteOrRoute;
        if (component == cell.site || component.nextComponent == cell.site) {
            cell.visitStatus = TourSiteVisiting;
        } else {
            NSInteger currentIndex = [detailVC.sites indexOfObject:component];
            while (currentIndex == NSNotFound) {
                component = component.nextComponent;
                currentIndex = [detailVC.sites indexOfObject:component];
            }
            NSInteger siteIndex = [detailVC.sites indexOfObject:cell.site];
            // the equality case is taken care above
            cell.visitStatus = (currentIndex > siteIndex) ? TourSiteVisited : TourSiteNotVisited;
        }
    } else {
        cell.visitStatus = TourSiteNotVisited;
    }
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    TourSiteOrRoute *site = [self.sites objectAtIndex:indexPath.row];
    [self selectTourSite:site];
    [self selectAnnotationForSite:site];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark cover flow

- (int)flowCoverNumberImages:(FlowCoverView *)view {
    return self.sites.count;
}

- (UIImage *)flowCover:(FlowCoverView *)view cover:(int)cover {
    TourSiteOrRoute *aSite = [self.sites objectAtIndex:cover];
    
    UIImage *image = [UIImage imageWithData:aSite.photo];
    if (!image) {
        image = [UIImage imageNamed:@"tours/tour_coverflow_loading.png"];
        [self requestImageForSite:aSite];
    }
    
    return image;
}

- (void)flowCover:(FlowCoverView *)view didFocusOnCover:(int)cover {
    TourSiteOrRoute *aSite = [self.sites objectAtIndex:cover];
    
    // change the label below the image
    UILabel *label = (UILabel *)[coverView viewWithTag:7283];
    label.text = aSite.title;
}

- (void)flowCover:(FlowCoverView *)view didSelect:(int)cover {
    TourSiteOrRoute *site = [self.sites objectAtIndex:cover];
    [self selectAnnotationForSite:site];
    [self selectTourSite:site];
}


- (void)hideCoverView {
    if (coverView) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [coverView removeFromSuperview];
        [coverView release];
        coverView = nil;
    }
}

#pragma mark connection

- (void)requestImageForSite:(TourSiteOrRoute *)site {
    ConnectionWrapper *connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    [connection requestDataFromURL:[NSURL URLWithString:site.photoURL] allowCachedResponse:YES];
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    for (int i = 0; i < self.sites.count; i++) {
        TourSiteOrRoute *aSite = [self.sites objectAtIndex:i];
        if ([aSite.photoURL isEqualToString:[wrapper.theURL absoluteString]]) {
            aSite.photo = data;
            [coverView clearCacheAtIndex:i];
            break;
        }
    }
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

#pragma mark MITMapViewDelegate

- (NSString *)distanceTextForSite:(TourSiteOrRoute *)site {
    NSString *text = nil;
    if (self.userLocation) {
        CLLocation *siteLocation = [[[CLLocation alloc] initWithLatitude:[site.latitude floatValue] longitude:[site.longitude floatValue]] autorelease];
        CLLocationDistance meters = [siteLocation distanceFromLocation:self.userLocation];
        text = [self textForDistance:meters];
    }
    return text;
}

- (NSString *)textForDistance:(CLLocationDistance)meters {
    NSString *measureSystem = [[NSLocale currentLocale] objectForKey:NSLocaleMeasurementSystem];
    BOOL isMetric = ![measureSystem isEqualToString:@"U.S."];
    
    CGFloat smoots = meters / METERS_PER_SMOOT;
    NSString *distanceString;
    if (!isMetric) {
        CGFloat feet = meters / METERS_PER_FOOT;
        if (feet * 2 > FEET_PER_MILE) {
            distanceString = [NSString stringWithFormat:@"%.1f miles", (feet / FEET_PER_MILE)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f feet",feet];
        }
    } else {
        if (meters > 1000) {
            distanceString = [NSString stringWithFormat:@"%.1f km", (meters / 1000)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f meters", meters];
        }
    }
    
    return [NSString stringWithFormat:@"%@ (%.0f smoots)", distanceString, smoots];
}

- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)userLocation {
    
    TourSiteOrRoute *currentSite = nil;
    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        currentSite = ((SiteDetailViewController *)callingViewController).siteOrRoute;
        if ([currentSite.type isEqualToString:@"route"]) {
            currentSite = currentSite.nextComponent;
        }
    }
    
    BOOL locationIsAcceptable = userLocation.horizontalAccuracy < 100;
    
    if (locationIsAcceptable && !self.userLocation) {
        if (![userLocation isOnCampus]) {
            locationIsAcceptable = NO;
            if (![userLocation isNearCampus]) {
                mapView.showsUserLocation = NO; // turn off location updating
                locateUserButton.enabled = NO;
            }
        }
    }
    
    CLLocation *centerLocation = nil;
    
    if (locationIsAcceptable) {
        locateUserButton.enabled = YES;
        CLLocationDistance meters = [self.userLocation distanceFromLocation:userLocation];
        
        if (!self.userLocation || meters > 30) {
            self.userLocation = userLocation;
            centerLocation = self.userLocation;
            [self.tableView reloadData];
            for (id annotation in self.mapView.annotations) {
                if ([annotation isKindOfClass:[TourSiteMapAnnotation class]]) {
                    TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
                    tourAnnotation.subtitle = [self distanceTextForSite:tourAnnotation.site];
                    if (tourAnnotation.site == currentSite) {
                        [self.mapView selectAnnotation:tourAnnotation animated:YES withRecenter:YES];
                    }
                }
            }
        }
    }
    else {
        CLLocationCoordinate2D defaultCenter = DEFAULT_MAP_CENTER;
        centerLocation = [[[CLLocation alloc] initWithLatitude:defaultCenter.latitude longitude:defaultCenter.longitude] autorelease];
    }
    
    if (![callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        [self selectAnnotationClosestTo:centerLocation];
    } else if (!locationIsAcceptable) {
        [self selectAnnotationForSite:currentSite];
    }
}

- (void)selectAnnotationForSite:(TourSiteOrRoute *)currentSite {
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[TourSiteMapAnnotation class]]) {
            TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
            if (tourAnnotation.site == currentSite) {
                [self.mapView selectAnnotation:tourAnnotation animated:YES withRecenter:YES];
                self.selectedAnnotation = tourAnnotation;
                break;
            }
        }
    }
}

- (void)selectAnnotationClosestTo:(CLLocation *)location {
    if (_didSelectAnnotation)
        return;
    
    TourSiteMapAnnotation *closestAnnotation = nil;
    
    CGFloat minDistance = MAXFLOAT;
    
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[TourSiteMapAnnotation class]]) {
            TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
            CLLocation *siteLocation = [[[CLLocation alloc] initWithLatitude:tourAnnotation.coordinate.latitude longitude:tourAnnotation.coordinate.longitude] autorelease];
            CGFloat distance = [siteLocation distanceFromLocation:location];
            if (distance < minDistance) {
                minDistance = distance;
                closestAnnotation = tourAnnotation;
            }
        }
    }
    
    [self.mapView selectAnnotation:closestAnnotation animated:YES withRecenter:YES];
    self.selectedAnnotation = closestAnnotation;
    
    _didSelectAnnotation = YES;
}

- (void)locateUserFailed:(MITMapView *)mapView {
    locateUserButton.enabled = NO;
    
    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        TourSiteOrRoute *currentSite = nil;
        if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
            currentSite = ((SiteDetailViewController *)callingViewController).siteOrRoute;
            if ([currentSite.type isEqualToString:@"route"]) {
                currentSite = currentSite.nextComponent;
            }
        }
        
        [self selectAnnotationForSite:currentSite];
    }
}

- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view {
    TourSiteMapAnnotation *annotation = (TourSiteMapAnnotation *)view.annotation;
    TourSiteOrRoute *site = annotation.site;
    [self selectTourSite:site];
}

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
    MITMapAnnotationView *annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:tourAnnotation reuseIdentifier:@"toursite"] autorelease];

    TourSiteOrRoute *site = tourAnnotation.site;
    TourSiteVisitStatus status;
    if ([callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        SiteDetailViewController *detailVC = (SiteDetailViewController *)callingViewController;
        TourSiteOrRoute *component = detailVC.siteOrRoute;
        if (component == site || component.nextComponent == site) { // current site
            status = TourSiteVisiting;
        } else {
            NSInteger currentIndex = [detailVC.sites indexOfObject:component];
            while (currentIndex == NSNotFound) {
                component = component.nextComponent;
                currentIndex = [detailVC.sites indexOfObject:component];
            }
            NSInteger siteIndex = [detailVC.sites indexOfObject:site];
            status = (currentIndex > siteIndex) ? TourSiteVisited : TourSiteNotVisited;
        }
    } else {
        status = TourSiteNotVisited;
    }
    
    annotationView.image = [ToursDataManager imageForVisitStatus:status];
    annotationView.layer.anchorPoint = CGPointMake(0.5, 0.6);
    annotationView.showsCustomCallout = YES;
    
    return annotationView;
}

- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    if (selectedAnnotation) {
        [self.mapView selectAnnotation:selectedAnnotation animated:YES withRecenter:YES];
        self.selectedAnnotation = nil;
    }
}

@end


@implementation TourOverviewTableViewCell

@synthesize site = _site;

- (TourSiteVisitStatus)visitStatus {
    return visitStatus;
}

- (void)setVisitStatus:(TourSiteVisitStatus)status {
    visitStatus = status;
    self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    self.accessoryView = [[[UIImageView alloc] initWithImage:[ToursDataManager imageForVisitStatus:status]] autorelease];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = CGRectMake(0, 0, TOUR_SITE_ROW_HEIGHT, TOUR_SITE_ROW_HEIGHT);
    MITThumbnailView *thumbView = (MITThumbnailView *)[self.contentView viewWithTag:4681];
    if (!thumbView) {
        thumbView = [[[MITThumbnailView alloc] initWithFrame:frame] autorelease];
        thumbView.delegate = self;
        thumbView.tag = 4681;
    }
    if (self.site.photo != nil) {
        thumbView.imageData = self.site.photo;
    } else {
        thumbView.imageURL = self.site.photoURL;
    }
    [self.contentView addSubview:thumbView];
    [thumbView loadImage];
    
    CGFloat labelX = TOUR_SITE_ROW_HEIGHT + 10;
    CGFloat labelWidth = self.frame.size.width - labelX - 40;

    UIFont *font = [UIFont boldSystemFontOfSize:17];
    self.textLabel.text = self.site.title;
	self.textLabel.numberOfLines = 2;
	self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
	CGSize labelSize = [self.textLabel.text sizeWithFont:font constrainedToSize:CGSizeMake(labelWidth, TOUR_SITE_ROW_HEIGHT * 0.6) lineBreakMode:UILineBreakModeTailTruncation];
	self.textLabel.font = font;
    self.textLabel.frame = CGRectMake(labelX, 5, labelWidth, labelSize.height);
    
    if (self.detailTextLabel.text) {
        self.detailTextLabel.frame = CGRectMake(labelX, round(TOUR_SITE_ROW_HEIGHT * 0.6) + 5, labelWidth, round(TOUR_SITE_ROW_HEIGHT * 0.4) - 5);
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    if ([thumbnail.imageURL isEqualToString:self.site.photoURL]) {
        self.site.photo = data;
    }
}

- (void)dealloc {
    self.site = nil;
    [super dealloc];
}

@end

