#import "TourOverviewViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "TourSiteOrRoute.h"
#import "MITThumbnailView.h"
#import "SiteDetailViewController.h"
#import "CoreDataManager.h"
#import "TourGeoLocation.h"
#import "TourSiteMapAnnotation.h"
#import "TourSideTripMapAnnotation.h"
#import "CampusTourSideTrip.h"
#import "StartingLocationViewController.h"
#import "CoreLocation+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITMapAnnotationView.h"
#import "MITNavigationController.h"


typedef enum {
    kOverviewSiteTitleLabelTag = 7283,
    kOverviewSiteLegendTag,
    kOverviewSiteScrimControlTag,
    kOverviewSiteGoBackAlertTag,
    kOverviewSiteCellThumbnailTag,
    kOverviewSiteCellStatusViewTag,
    kOverviewSiteCellSideTripLabelTag,
    kOverviewSiteCellSideTripIconTag
}
TourOverviewTags;

@interface TourOverviewViewController ()
@property (nonatomic,strong) IBOutlet UIToolbar *toolBar;
@property (nonatomic,strong) IBOutlet UISegmentedControl *mapListToggle;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *locateUserButton;

@property (nonatomic) UIInterfaceOrientation currentOrientation;
@property (nonatomic) BOOL displayingMap;
@property (nonatomic) BOOL didSelectAnnotation;
@property (nonatomic) NSInteger selectedSiteIndex;

- (NSString *)distanceTextForLocation:(id<TourGeoLocation>)location;
- (NSString *)textForDistance:(CLLocationDistance)meters;
- (void)selectAnnotationClosestTo:(CLLocation *)location;
- (void)showStartSuggestions:(id)sender;

- (void)setupNotSureScrim;
- (void)setupMapLegend;
- (MITThumbnailView *)thumbnailViewForCell:(TourOverviewTableViewCell *)cell;
+ (TourSiteOrRoute *)siteForTourComponent:(TourComponent *)tourComponent;
- (void)updateTourComponents;

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

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
        self.components = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    self.mapView.showsUserLocation = YES;
    [self.mapView addTileOverlay];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.mapView.showsUserLocation = NO;
    [self.mapView removeTileOverlay];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationItem.title = @"Tour Overview";
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(dismiss:)];
    } else {
        self.navigationItem.title = @"Starting Point";
    }    
    
    [self updateTourComponents];
    
    self.locateUserButton.image = [UIImage imageNamed:MITImageBarButtonLocation];
    
    [self showMap:YES];
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectionDidComplete {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)orientationChanged:(NSNotification *)notification {
    // if we push a view controller onto list mode, we will continue to receive notifications
    if (self.navigationController.visibleViewController != self)
        return;
    
    UIDevice *device = [notification object];
    
    if (UIDeviceOrientationIsPortrait(device.orientation)) {
		[[UIApplication sharedApplication] 
         setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        
    } else {
		[[UIApplication sharedApplication] 
         setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }    
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.mapView.delegate = nil;
    self.mapView = nil;
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
    switch (self.mapListToggle.selectedSegmentIndex) {
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

- (IBAction)toggleHideSideTrips:(id)sender {
    self.hideSideTrips = !self.hideSideTrips;
    
    @autoreleasepool {
        if (self.hideSideTrips) {
            NSMutableArray *indexPathsToDelete = 
            [NSMutableArray arrayWithCapacity:[self.components count]];
            NSMutableArray *componentsToRemove = 
            [NSMutableArray arrayWithCapacity:[self.components count]];
            
            [self.components enumerateObjectsUsingBlock:
             ^(id obj, NSUInteger idx, BOOL *stop) {
                 if ([obj isKindOfClass:[CampusTourSideTrip class]]) {
                     [componentsToRemove addObject:obj];
                     [indexPathsToDelete addObject:
                      [NSIndexPath indexPathForRow:idx inSection:0]];
                 }
             }];
            
            [self.tableView beginUpdates];
            
            [self.components removeObjectsInArray:componentsToRemove];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete 
                                  withRowAnimation:UITableViewRowAnimationFade];
            
            [self.tableView endUpdates];
            
            self.sideTripsItem.title = @"Show side trips";
        } else {
            NSMutableArray *indexPathsToAdd = 
            [NSMutableArray arrayWithCapacity:[self.components count]];
            NSArray *currentlyShowingComponents = [self.components copy];
            [self updateTourComponents];
            [self.components enumerateObjectsUsingBlock:
             ^(id obj, NSUInteger idx, BOOL *stop) {
                 if (![currentlyShowingComponents containsObject:obj]) {
                     [indexPathsToAdd addObject:
                      [NSIndexPath indexPathForRow:idx inSection:0]];
                 }
             }];
            
            [self.tableView beginUpdates];
            
            [self.tableView insertRowsAtIndexPaths:indexPathsToAdd
                                  withRowAnimation:UITableViewRowAnimationFade];
            
            [self.tableView endUpdates];
            self.sideTripsItem.title = @"Hide side trips";
        }        
    }
}

- (void)showStartSuggestions:(id)sender {
    StartingLocationViewController *vc = [[StartingLocationViewController alloc] init];
    vc.startingLocations = [[ToursDataManager sharedManager] startLocationsForTour];
    vc.overviewController = self;
    
    UINavigationController *dummyVC = [[MITNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:dummyVC animated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        SiteDetailViewController *siteDetailVC = (SiteDetailViewController *)self.callingViewController;
        siteDetailVC.sideTrip = nil;
        [siteDetailVC jumpToSite:self.selectedSiteIndex];
        
        [self selectionDidComplete];
    }
}

- (void)refreshAnnotationsAndRoutes {
    [self.mapView removeAllRoutes];
    [self.mapView removeAllAnnotations:NO];
    
    MITGenericMapRoute *mapRoute = [[ToursDataManager sharedManager] mapRouteForTour];
    self.mapView.region = [self.mapView regionForRoute:mapRoute];
    [self.mapView addRoute:mapRoute];
    
    if(self.sideTrip) {
        // set the map extent
        CGFloat lat1 = [self.sideTrip.latitude floatValue];
        CGFloat lon1 = [self.sideTrip.longitude floatValue];
        CGFloat lat2 = [self.sideTrip.site.latitude floatValue];
        CGFloat lon2 = [self.sideTrip.site.longitude floatValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(0.5 * (lat1 + lat2), 0.5 * (lon1 + lon2));

        CGFloat deltaLat = fabsf(lat1 - lat2);
        CGFloat deltaLon = fabsf(lon1 - lon2);
        self.mapView.region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(deltaLat*2.2, deltaLon*2.2));
        
        // route from sidetrip to its parent site
        MITGenericMapRoute *sideTripRoute = [[ToursDataManager sharedManager] mapRouteFromSideTripToSite:self.sideTrip];
        [self.mapView addRoute:sideTripRoute];
        
        // add sidetrip annotation
        TourSideTripMapAnnotation *annotation = [[TourSideTripMapAnnotation alloc] init];
        annotation.sideTrip = self.sideTrip;
        if(self.userLocation != nil) {
            annotation.subtitle = [self distanceTextForLocation:self.sideTrip];
        }
        [self.mapView addAnnotation:annotation];
        [self.mapView selectAnnotation:annotation animated:YES withRecenter:YES];
        self.selectedAnnotation = annotation; // attempt select again after annotation views are populated
    }
    
    for (TourComponent *component in self.components) {
        if([component isKindOfClass:[CampusTourSideTrip class]]) {
            // dont add annotations for sidetrips (except for the one already added above
            continue;
        }
        TourSiteOrRoute *aSite = (TourSiteOrRoute *)component;
        if (aSite) {                    
            TourSiteMapAnnotation *annotation = [[TourSiteMapAnnotation alloc] init];
            if (self.userLocation != nil) {
                annotation.subtitle = 
                [self distanceTextForLocation:aSite];
            }
            annotation.site = aSite;
            [self.mapView addAnnotation:annotation];
            
            if (!self.sideTrip) { // dont select a stop (if sidetrip is specified) {
                if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
                    if (aSite == ((SiteDetailViewController *)self.callingViewController).siteOrRoute
                        || aSite == ((SiteDetailViewController *)self.callingViewController).siteOrRoute.nextComponent)
                    {
                        [self.mapView selectAnnotation:annotation animated:YES withRecenter:YES];
                        self.selectedAnnotation = annotation; // attempt select again after annotation views are populated
                    }
                }
            }
        }
    }
}

- (void)showMap:(BOOL)showMap {
    
    NSMutableArray *toolbarItems = [self.toolBar.items mutableCopy];
    
    self.mapListToggle.selectedSegmentIndex = showMap ? MapListSegmentMap : MapListSegmentList;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.toolBar.tintColor = [UIColor mit_tintColor];
    }
    
    if (showMap) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width,
                                  self.view.frame.size.height - self.toolBar.frame.size.height);
        
        [self.tableView removeFromSuperview];
        if (!self.mapView) {
            self.mapView = [[MITMapView alloc] initWithFrame:frame];
            self.mapView.delegate = self;
            self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            [self refreshAnnotationsAndRoutes];
            
            self.mapView.showsUserLocation = YES;
        }
        
        [self.view addSubview:self.mapView];
        
        if (![toolbarItems containsObject:self.locateUserButton]) {
            [toolbarItems addObject:self.locateUserButton];
        }
        if ([toolbarItems containsObject:self.sideTripsItem]) {
            [toolbarItems removeObject:self.sideTripsItem];
        }
    } else {
        [self.mapView removeFromSuperview];
        self.mapView = nil;
        
        CGRect frame = CGRectMake(0, 64., self.view.frame.size.width,
                                  self.view.frame.size.height - self.toolBar.frame.size.height - 64.);
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            frame = CGRectMake(0, 0, self.view.frame.size.width,
                               self.view.frame.size.height - self.toolBar.frame.size.height);
        }
        
        if (!self.tableView) {
            self.tableView = [[UITableView alloc] initWithFrame:frame
                                                          style:UITableViewStylePlain];
            self.tableView.rowHeight = TOUR_SITE_ROW_HEIGHT;
            self.tableView.delegate = self;
            self.tableView.dataSource = self;
            self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        [self.view addSubview:self.tableView];
        
        if ([toolbarItems containsObject:self.locateUserButton]) {
            [toolbarItems removeObject:self.locateUserButton];
        }
        
        if (![self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
            // Add item hiding/showing side trips.
            if (!self.sideTripsItem) {
                self.sideTripsItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide side trips"
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(toggleHideSideTrips:)];
            }
            [toolbarItems addObject:self.sideTripsItem];
        }
    }
    
    self.displayingMap = showMap;
    
    [self.toolBar setItems:toolbarItems animated:NO];

    if (self.displayingMap) {
        if (![self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
            [self setupNotSureScrim];
        } else {
            [self setupMapLegend];
        }
    }
    
}

- (void)setupMapLegend {
    UIView *legend = [self.view viewWithTag:kOverviewSiteLegendTag];
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
        
        legend = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                          self.view.frame.size.height - self.toolBar.frame.size.height - legendHeight,
                                                          self.view.frame.size.width,
                                                          legendHeight)];
        legend.backgroundColor = [UIColor clearColor];
        legend.layer.cornerRadius = 5.0;
        legend.tag = kOverviewSiteLegendTag;
        legend.userInteractionEnabled = NO;
        legend.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        UIImage *backgroundImage = [UIImage imageNamed:MITImageToursMapLegendOverlay];
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0
                                                                                                               topCapHeight:0]];
        backgroundView.frame = CGRectMake(0, -4, legend.frame.size.width, legend.frame.size.height + 4); // compensate for transparent pixels
        [legend addSubview:backgroundView];
        
        CGRect frame = CGRectZero;
        frame.origin.x = keyPadding;
        for (NSInteger i = 0; i < [images count]; i++) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:images[i]];
            frame.size = imageView.frame.size;
            imageView.frame = frame;
            [legend addSubview:imageView];
            
            frame.origin.x += imageView.frame.size.width + markerSpacing;
            NSString *labelText = labels[i];
            CGSize labelSize = [labelText sizeWithFont:labelFont];
            frame.size.width = labelSize.width;
            
            UILabel *label = [[UILabel alloc] initWithFrame:frame];
            label.backgroundColor = [UIColor clearColor];
            label.text = labelText;
            label.font = labelFont;
            [legend addSubview:label];
            
            frame.origin.x += label.frame.size.width + keySpacing;
        }
        
        // resize map view so google logo shows
        CGRect mapFrame = self.mapView.frame;
        mapFrame.size.height -= legend.frame.size.height;
        self.mapView.frame = mapFrame;
        
        [legend removeFromSuperview];
        [self.view addSubview:legend];
    }    
}

- (void)setupNotSureScrim {
    UIControl *control = 
    (UIControl *)[self.view viewWithTag:kOverviewSiteScrimControlTag];
    if (!control) {
        UIImage *scrim = [UIImage imageNamed:MITImageToursScrimNotSureTop];
        
        CGRect frame = CGRectMake(0, 64., self.view.frame.size.width, scrim.size.height);
        
        control = [[UIControl alloc] initWithFrame:frame];
        control.backgroundColor = [UIColor clearColor];
        control.tag = kOverviewSiteScrimControlTag;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:scrim];
        [control addSubview:imageView];
        
        frame = control.bounds;
        frame.origin.x += 7;
        frame.origin.y += 2;
        frame.size.width -= 14;
        frame.size.height = 21;
        
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.text = @"Not sure where to begin?";
        label.font = [UIFont boldSystemFontOfSize:15];
        label.textColor = [UIColor colorWithHexString:@"#202020"];
        label.backgroundColor = [UIColor clearColor];
        label.userInteractionEnabled = NO;
        
        frame.origin.y += 17;
        
        UILabel *anotherLabel = [[UILabel alloc] initWithFrame:frame];
        anotherLabel.text = @"Browse suggested starting points.";
        anotherLabel.font = [UIFont systemFontOfSize:15];
        anotherLabel.textColor = [UIColor colorWithHexString:@"#404040"];
        anotherLabel.backgroundColor = [UIColor clearColor];
        anotherLabel.userInteractionEnabled = NO;
        
        [control addSubview:label];
        [control addSubview:anotherLabel];
        [control addTarget:self action:@selector(showStartSuggestions:) forControlEvents:UIControlEventTouchUpInside];
		
		UIImageView *chevronView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
		chevronView.center = CGPointMake(control.frame.size.width - 10, (round(control.frame.size.height / 2)-2));
		chevronView.userInteractionEnabled = NO;
		[control addSubview:chevronView];
    }
    
    [control removeFromSuperview];
    [self.view addSubview:control];
}

- (void)selectTourComponent:(TourComponent *)component {
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        SiteDetailViewController *siteDetailVC = (SiteDetailViewController *)self.callingViewController;
        self.selectedSiteIndex = [siteDetailVC.sites indexOfObject:component];
        if ([component isKindOfClass:[CampusTourSideTrip class]]) {
            [self dismiss:nil];
        }
        else if (siteDetailVC.showingConclusionScreen && 
            siteDetailVC.siteOrRoute == component) {
            [siteDetailVC previousButtonPressed:nil];
            [self dismiss:nil];
        }
        else if (siteDetailVC.siteOrRoute == component || 
                 siteDetailVC.siteOrRoute.nextComponent == component) {
            // user selected current stop, so just show then what they were looking at before
            if(siteDetailVC.sideTrip) {
                siteDetailVC.sideTrip = nil;
                [siteDetailVC jumpToSite:self.selectedSiteIndex];
            }
            [self dismiss:nil];
        }
        else if (siteDetailVC.siteOrRoute.nextComponent.nextComponent == component && 
                 siteDetailVC.firstSite != component) {
            // user selected next stop; show directions to it
            siteDetailVC.sideTrip = nil;
            [siteDetailVC nextButtonPressed:nil];
            [self selectionDidComplete];
        }
        else {
            // user is skipping ahead or going back
            if (self.selectedSiteIndex == NSNotFound) {
                for (TourSiteOrRoute *aSite in siteDetailVC.sites) {
                    self.selectedSiteIndex++;
                    if ([aSite.componentID isEqualToString:component.componentID]) {
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
            NSInteger difference = self.selectedSiteIndex - currentSiteIndex;
            NSString *message;
            if (difference < 0) {
                message = [NSString stringWithFormat:@"Are you sure you want to go back %d stops?", -difference];
            } else {
                message = [NSString stringWithFormat:@"Are you sure you want to skip ahead %d stops?", difference];
            }
            
            NSString *title = [NSString string];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                       otherButtonTitles:@"OK", nil];
            alertView.tag = kOverviewSiteGoBackAlertTag;
            [alertView show];
        }
        
    } else {
        // This is the case in which the view controller that pushed us to the 
        // stack is not a SiteDetailViewController.
        SiteDetailViewController *detailVC = [[SiteDetailViewController alloc] init];
        if ([component isKindOfClass:[CampusTourSideTrip class]]) {

            CampusTourSideTrip *aSideTrip =  (CampusTourSideTrip *)component;
            detailVC.sideTrip = aSideTrip;
            TourSiteOrRoute *siteOrRoute = (TourSiteOrRoute *)aSideTrip.component;
            TourSiteOrRoute *site;            
            if([siteOrRoute.type isEqualToString:@"site"]) {
                site = siteOrRoute;
            } else {
                site = siteOrRoute.previousComponent;
            }
            detailVC.siteOrRoute = siteOrRoute;
            detailVC.firstSite = site;           
        } else {
            TourSiteOrRoute *site = [[self class] siteForTourComponent:component];
            [self selectAnnotationForSite:site];
            detailVC.siteOrRoute = site;
            detailVC.firstSite = site;
        }
        [self.navigationController pushViewController:detailVC animated:YES];

    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.components count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* CellIdentifier = @"Cell";

    TourOverviewTableViewCell *cell = (TourOverviewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TourOverviewTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }    

    cell.tourComponent = self.components[indexPath.row];
    cell.accessoryView = [self thumbnailViewForCell:cell];

    TourSiteOrRoute *site = [[self class] siteForTourComponent:cell.tourComponent];
                    
    if (self.userLocation) {
        if ([cell.tourComponent conformsToProtocol:@protocol(TourGeoLocation)]) {
            id<TourGeoLocation> geoLocation = (id<TourGeoLocation>)cell.tourComponent;
            cell.detailTextLabel.text = [self distanceTextForLocation:geoLocation];
        }
    }
    
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        SiteDetailViewController *detailVC = (SiteDetailViewController *)self.callingViewController;
        TourSiteOrRoute *component = detailVC.siteOrRoute;
        if (component == site || component.nextComponent == site) {
            cell.visitStatus = TourSiteVisiting;
        } else {
            NSInteger currentIndex = [detailVC.sites indexOfObject:component];
            while (currentIndex == NSNotFound) {
                component = component.nextComponent;
                currentIndex = [detailVC.sites indexOfObject:component];
            }
            NSInteger siteIndex = [detailVC.sites indexOfObject:site];
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
    TourComponent *component = self.components[indexPath.row];
    TourSiteOrRoute *site = 
    [[self class] siteForTourComponent:self.components[indexPath.row]];

    if (site) {
        [self selectTourComponent:component];
    }
    else {
        DDLogVerbose(@"Could not find TourSiteOrRoute for selected row!");
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (MITThumbnailView *)thumbnailViewForCell:(TourOverviewTableViewCell *)cell {
    MITThumbnailView *thumbView = 
    (MITThumbnailView *)[cell.contentView viewWithTag:kOverviewSiteCellThumbnailTag];
    if (!thumbView) {
        CGRect frame = 
        CGRectMake(0, 0, TOUR_SITE_ROW_HEIGHT, TOUR_SITE_ROW_HEIGHT);
        thumbView = [[MITThumbnailView alloc] initWithFrame:frame];
        thumbView.delegate = cell;
        thumbView.tag = kOverviewSiteCellThumbnailTag;
    }
    if (cell.tourComponent.photo != nil) {
        thumbView.imageData = cell.tourComponent.photo;
    } else {
        thumbView.imageURL = cell.tourComponent.photoURL;
    }
    //[cell.contentView addSubview:thumbView];
    [thumbView loadImage];
    return thumbView;
}

+ (TourSiteOrRoute *)siteForTourComponent:(TourComponent *)tourComponent {
    TourSiteOrRoute *site = nil;
    // This check to see if it's either a TourSiteOrRoute or a CampusTourSideTrip.
    if ([tourComponent isKindOfClass:[TourSiteOrRoute class]]) {
        site = (TourSiteOrRoute *)tourComponent;
    }
    else if ([tourComponent isKindOfClass:[CampusTourSideTrip class]]) {
        site = (TourSiteOrRoute *)[(CampusTourSideTrip *)tourComponent component];
    }
    return site;
}

- (void)updateTourComponents {
    [self.components removeAllObjects];
    
    NSArray *allSites = nil;
    
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        allSites = ((SiteDetailViewController *)self.callingViewController).sites;
    } else {
        // We want to show side trips only if we were NOT pushed to the nav stack 
        // by a SiteDetailViewController.
        allSites = [[ToursDataManager sharedManager] allSitesOrSideTripsForSites:
                    [[ToursDataManager sharedManager] allSitesForTour]];
    }    
    
    [self.components addObjectsFromArray:allSites];
}


#pragma mark MITMapViewDelegate

- (NSString *)distanceTextForLocation:(id<TourGeoLocation>)location {
    NSString *text = nil;
    if (self.userLocation) {
        CLLocation *siteLocation = [[CLLocation alloc] initWithLatitude:[location.latitude floatValue]
                                                              longitude:[location.longitude floatValue]];
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
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        currentSite = ((SiteDetailViewController *)self.callingViewController).siteOrRoute;
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
                self.locateUserButton.enabled = NO;
            }
        }
    }
    
    CLLocation *centerLocation = nil;
    
    if (locationIsAcceptable) {
        self.locateUserButton.enabled = YES;
        CLLocationDistance meters = [self.userLocation distanceFromLocation:userLocation];
        
        if (!self.userLocation || meters > 30) {
            self.userLocation = userLocation;
            centerLocation = self.userLocation;
            [self.tableView reloadData];
            for (id annotation in self.mapView.annotations) {
                if ([annotation isKindOfClass:[TourMapAnnotation class]]) {
                    TourMapAnnotation *tourAnnotation = (TourMapAnnotation *)annotation;
                    tourAnnotation.subtitle = [self distanceTextForLocation:tourAnnotation.tourGeoLocation];
                }
            }
            [self.mapView refreshCallout];
        }
    }
    else {
        CLLocationCoordinate2D defaultCenter = DEFAULT_MAP_CENTER;
        centerLocation = [[CLLocation alloc] initWithLatitude:defaultCenter.latitude
                                                    longitude:defaultCenter.longitude];
    }
    
    if(!self.sideTrip && !currentSite) {
        [self selectAnnotationClosestTo:centerLocation];
    }
}


- (void)selectAnnotationForSite:(TourSiteOrRoute *)currentSite {
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[TourSiteMapAnnotation class]]) {
            TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
            if ([tourAnnotation.site isEqual:currentSite]) {
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
            CLLocation *siteLocation = [[CLLocation alloc] initWithLatitude:tourAnnotation.coordinate.latitude
                                                                   longitude:tourAnnotation.coordinate.longitude];
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
    self.locateUserButton.enabled = NO;
    
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
        TourSiteOrRoute *currentSite = nil;
        if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]]) {
            currentSite = ((SiteDetailViewController *)self.callingViewController).siteOrRoute;
            if ([currentSite.type isEqualToString:@"route"]) {
                currentSite = currentSite.nextComponent;
            }
        }
        
        [self selectAnnotationForSite:currentSite];
    }
}

- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view {
    TourMapAnnotation *annotation = (TourSiteMapAnnotation *)view.annotation;
    TourComponent *component = annotation.component;
    [self selectTourComponent:component];
}

- (UIImageView*)tourDirectionMarkerFromLocation:(id<TourGeoLocation>)startLocation
                                     toLocation:(id<TourGeoLocation>)endLocation
                                      withImage:(UIImage*)markerImage
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:markerImage];
    
    CGFloat deltaX = CGRectGetMidX(imageView.bounds);
    CGFloat deltaY = CGRectGetMidY(imageView.bounds);
    
    MKMapPoint startPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake([startLocation.latitude doubleValue],
                                                                               [startLocation.longitude doubleValue]));
    MKMapPoint endPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake([endLocation.latitude doubleValue],
                                                                             [endLocation.longitude doubleValue]));
    CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-deltaX, -deltaY),
                                                          CGAffineTransformMakeRotation(atan2(endPoint.y - startPoint.y,
                                                                                              endPoint.x - startPoint.x)));
    imageView.transform = CGAffineTransformTranslate(transform, deltaX, deltaY);
    return imageView;
}

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MITMapAnnotationView *annotationView = [[MITMapAnnotationView alloc] initWithAnnotation:annotation
                                                                             reuseIdentifier:@"toursite"];

    TourSiteVisitStatus status;
    if ([self.callingViewController isKindOfClass:[SiteDetailViewController class]] &&
        [annotation isKindOfClass:[TourSiteMapAnnotation class]]) {
        
        TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
        TourSiteOrRoute *site = tourAnnotation.site;  
        SiteDetailViewController *detailVC = (SiteDetailViewController *)self.callingViewController;
        
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
    annotationView.calloutOffset = CGPointMake(0,annotationView.image.size.height / 2.0);
    
    // if a side trip is being displayed
    // we need to override the sidetrip and its sites image
    // to show the back and forth arrow
    if(self.sideTrip) {
        // if a side trip is being displayed
        // we need to show the arrow back to the main site
        if([annotation isKindOfClass:[TourSideTripMapAnnotation class]]) {
            TourSideTripMapAnnotation *sideTripAnnotation = annotation;
            CampusTourSideTrip *source = sideTripAnnotation.sideTrip;        
            TourSiteOrRoute *dest = source.site;
            
            annotationView.image = nil;
            annotationView.calloutOffset = CGPointZero;
            UIImageView *markerView = [self tourDirectionMarkerFromLocation:source
                                                                  toLocation:dest
                                                                   withImage:[UIImage imageNamed:MITImageToursAnnotationArrowStart]];
            [annotationView addSubview:markerView];
            annotationView.frame = CGRectOffset(markerView.bounds,
                                                -CGRectGetMidX(markerView.frame),
                                                -CGRectGetMidY(markerView.frame));
        } else {
            TourSiteMapAnnotation *siteAnnotation = annotation;
            if(siteAnnotation.site == self.sideTrip.component) {
                
                annotationView.image = nil;
                annotationView.calloutOffset = CGPointZero;
                UIImageView *markerView = [self tourDirectionMarkerFromLocation:self.sideTrip
                                                                      toLocation:siteAnnotation.site
                                                                       withImage:[UIImage imageNamed:MITImageToursAnnotationArrowEnd]];
                [annotationView addSubview:markerView];
                annotationView.frame = CGRectOffset(markerView.bounds,
                                                    -CGRectGetMidX(markerView.frame),
                                                    -CGRectGetMidY(markerView.frame));
            }
        }
    }
    
    annotationView.canShowCallout = YES;
    annotationView.showsCustomCallout = YES;
    
    return annotationView;
}

- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    if (self.selectedAnnotation) {
        self.selectedAnnotation = nil;
    }
}

@end


@implementation TourOverviewTableViewCell

- (void)setVisitStatus:(TourSiteVisitStatus)status {
    _visitStatus = status;
    
    //self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    UIImage *statusImage = [ToursDataManager imageForVisitStatus:status];
    UIImageView *statusView = 
    (UIImageView *)[self.contentView viewWithTag:kOverviewSiteCellStatusViewTag];
    if (!statusView) {        
        statusView = [[UIImageView alloc] initWithImage:statusImage];
        statusView.tag = kOverviewSiteCellStatusViewTag;
        [self.contentView addSubview:statusView];
    }
    else {
        statusView.image = statusImage;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat mainTextLabelX = 30;
    CGFloat mainTextLabelY = 5;
    CGFloat mainTextLabelWidth = self.frame.size.width - mainTextLabelX - 90;
    
    UILabel *sideTripLabel = 
    (UILabel *)[self.contentView viewWithTag:kOverviewSiteCellSideTripLabelTag];
    if (!sideTripLabel) {
        sideTripLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainTextLabelX + 20, 5, mainTextLabelWidth, 20)];
        sideTripLabel.tag = kOverviewSiteCellSideTripLabelTag;
        sideTripLabel.textColor = [UIColor lightGrayColor];
        sideTripLabel.text = @"Side Trip:";
        [self.contentView addSubview:sideTripLabel];
    }
    
    UIImageView *sideTripIconView = 
    (UIImageView *)[self.contentView viewWithTag:kOverviewSiteCellSideTripIconTag];
    if (!sideTripIconView) {
        sideTripIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursSideTripArrow]];
        sideTripIconView.tag = kOverviewSiteCellSideTripIconTag;
        
        CGRect iconFrame = sideTripIconView.frame;
        iconFrame.origin.x = mainTextLabelX;
        iconFrame.origin.y = 5;
        
        sideTripIconView.frame = iconFrame;
        [self.contentView addSubview:sideTripIconView];
    }
    
    if ([self.tourComponent isKindOfClass:[CampusTourSideTrip class]]) {
        mainTextLabelY += 25;
        sideTripLabel.alpha = 1.0f;
        sideTripIconView.alpha = 1.0f;
        // Don't show distance for side trips.
        self.detailTextLabel.alpha = 0.0f;
    }
    else {
        sideTripLabel.alpha = 0.0f;
        sideTripIconView.alpha = 0.0f;
        self.detailTextLabel.alpha = 1.0f;
    }
    
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    self.textLabel.text = [self.tourComponent title];
	self.textLabel.numberOfLines = 2;
	self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	CGSize labelSize = 
    [self.textLabel.text sizeWithFont:font constrainedToSize:
     CGSizeMake(mainTextLabelWidth, TOUR_SITE_ROW_HEIGHT * 0.6) 
                        lineBreakMode:NSLineBreakByTruncatingTail];
	self.textLabel.font = font;
    self.textLabel.frame = CGRectIntegral(CGRectMake(mainTextLabelX, mainTextLabelY,
                                      mainTextLabelWidth, labelSize.height));
    
    if (self.detailTextLabel.text) {
        self.detailTextLabel.frame = 
        CGRectIntegral(CGRectMake(mainTextLabelX, round(TOUR_SITE_ROW_HEIGHT * 0.6) + 5,
                   mainTextLabelWidth, round(TOUR_SITE_ROW_HEIGHT * 0.4) - 5));
    }
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.separatorInset = UIEdgeInsetsMake(0, mainTextLabelX, 0, 0);
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    if ([thumbnail.imageURL isEqualToString:self.tourComponent.photoURL]) {
        [self.tourComponent setPhoto:data];
    }
}

@end

