#import <QuartzCore/QuartzCore.h>
#import "CampusMapViewController.h"
#import "NSString+SBJSON.h"
#import "MITMapSearchResultAnnotation.h"
#import "MITMapSearchResultsVC.h"
#import "MITMapDetailViewController.h"
#import "ShuttleDataManager.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "MITUIConstants.h"
#import "MITConstants.h"
#import "MapSearch.h"
#import "CoreDataManager.h"
#import "MapSelectionController.h"
#import "CoreLocation+MITAdditions.h"
#import "MITModuleURL.h"
#import "MITMapAnnotationView.h"

#define kSearchBarWidth 270
#define kSearchBarCancelWidthDiff 28

#define kAPISearch		@"Search"

#define kNoSearchResultsTag 31678

#define kPreviousSearchLimit 25


@interface CampusMapViewController ()
@property (nonatomic, strong) MITMapView* mapView;
@property (nonatomic, strong) MITModuleURL* url;

@property (nonatomic, strong) UIView *searchBarView;
@property (nonatomic, strong) UIToolbar* toolbar;
@property (nonatomic, strong) UIToolbar* geoToolbar;
@property (nonatomic, strong) UIToolbar* cancelToolbar;

@property (nonatomic, strong) UITableView* categoryTableView;
@property (nonatomic, strong) UIBarButtonItem* cancelSearchButton;
@property (nonatomic, strong) UIBarButtonItem* shuttleButton;
@property (nonatomic, strong) UIBarButtonItem* viewTypeButton;

@property (nonatomic, strong) NSMutableArray* shuttleAnnotations;
@property (nonatomic, strong) NSArray* filteredSearchResults;
@property (nonatomic, strong) NSArray* categories;

@property (nonatomic, strong) MITMapSearchResultsVC* searchResultsVC;
@property (nonatomic, strong) MapSelectionController* selectionVC;

@property (nonatomic, assign) SEL searchFilter;
@property (nonatomic, assign) BOOL displayShuttles;

@property (nonatomic) BOOL wasShowingUserLocation;

- (void)updateMapListButton;
- (void)addAnnotationsForShuttleStops:(NSArray*)shuttleStops;
- (void)noSearchResultsAlert;
- (void)saveRegion; // a convenience method for saving the mapView's current region (for saving state)

@end

@implementation CampusMapViewController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	// create our own view
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 364)];
	
	self.viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Browse" style:UIBarButtonItemStylePlain target:self action:@selector(viewTypeChanged:)];
	self.navigationItem.rightBarButtonItem = self.viewTypeButton;
	
    
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), NAVIGATION_BAR_HEIGHT)];
    searchBarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"global/toolbar-background.png"]];	
    {
        UIToolbar *geoToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
        geoToolbar.translucent = NO;
        geoToolbar.tintColor = SEARCH_BAR_TINT_COLOR;
        [geoToolbar setBackgroundImage:[UIImage imageNamed:@"global/toolbar-background.png"]
                    forToolbarPosition:UIToolbarPositionAny
                            barMetrics:UIBarMetricsDefault];
        
        UIImage *buttonImage = [UIImage imageNamed:@"map/map_button_icon_locate"];
        UIBarButtonItem *geoButton = [[UIBarButtonItem alloc] initWithImage:buttonImage
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(geoLocationTouched:)];
        geoButton.width = buttonImage.size.width + 10;
        [geoToolbar setItems:@[geoButton]];
        [searchBarView addSubview:geoToolbar];
        self.geoToolbar = geoToolbar;
    }
    
    {
        UIToolbar *cancelToolbar = [[UIToolbar alloc] init];
        cancelToolbar.frame = CGRectMake(kSearchBarWidth - kSearchBarCancelWidthDiff,
                                         0,
                                         320 - kSearchBarWidth + kSearchBarCancelWidthDiff,
                                         NAVIGATION_BAR_HEIGHT);
        cancelToolbar.translucent = NO;
        cancelToolbar.tintColor = SEARCH_BAR_TINT_COLOR;
        
        [cancelToolbar setBackgroundImage:[UIImage imageNamed:@"global/toolbar-background.png"]
                       forToolbarPosition:UIToolbarPositionAny
                               barMetrics:UIBarMetricsDefault];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancelSearch)];
        [cancelToolbar setItems:@[cancelButton]];
        self.cancelToolbar = cancelToolbar;
    }
    
    
    {
        // add a search bar to our view
        _searchBar = [[ UISearchBar alloc] initWithFrame:CGRectMake(0, 0, kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
        [_searchBar setDelegate:self];
        _searchBar.placeholder = NSLocalizedString(@"Search MIT Campus", nil);
        _searchBar.translucent = NO;
        _searchBar.backgroundImage = [UIImage imageNamed:@"global/toolbar-background.png"];
        _searchBar.showsBookmarkButton = YES; // we'll be adding a custom bookmark button
        _searchBar.showsCancelButton = NO;
        [_searchBar setImage:[UIImage imageNamed:@"map/searchfield_star.png"]
            forSearchBarIcon:UISearchBarIconBookmark
                       state:UIControlStateNormal];
        [searchBarView addSubview:_searchBar];
    }
    
    self.toolbar = self.geoToolbar;
    
    self.searchBarView = searchBarView;
    [self.view addSubview:searchBarView];
	
    
	// create the map view controller and its view to our view.
	self.mapView = [[MITMapView alloc] initWithFrame: CGRectMake(0, self.searchBar.frame.size.height, 320, CGRectGetHeight(self.view.bounds) - self.searchBar.frame.size.height)];
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.mapView setRegion:MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN)];
	[self.view addSubview:self.mapView];
	self.mapView.delegate = self;
    [self.mapView fixateOnCampus];
    
	self.url = [[MITModuleURL alloc] initWithTag:CampusMapTag];
	
}

- (void)setDisplayingList:(BOOL)displayingList {
    _displayingList = displayingList;
    [self updateMapListButton];
}

- (void)setHasSearchResults:(BOOL)hasSearchResults {
    _hasSearchResults = hasSearchResults;
    [self updateMapListButton];
}

- (void)updateMapListButton {
    NSString *buttonTitle = @"Browse";
	if (self.displayingList) {
		buttonTitle = @"Map";
	} else if (self.hasSearchResults) {
        buttonTitle = @"List";
    }
    self.navigationItem.rightBarButtonItem.title = buttonTitle;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Campus Map";
}

-(void) viewWillAppear:(BOOL)animated {
    [self.mapView addTileOverlay];
    self.mapView.showsUserLocation = self.wasShowingUserLocation;
    
    [self updateMapListButton];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.mapView removeTileOverlay];
    self.wasShowingUserLocation = self.mapView.showsUserLocation;
    self.mapView.showsUserLocation = NO;
}

-(void) viewDidAppear:(BOOL)animated
{
	// show the annotations
	
	[super viewDidAppear:animated];
	
	// if there is a bookmarks view controller hanging around, dismiss and release it.
	if(nil != self.selectionVC)
	{
		[self.selectionVC dismissModalViewControllerAnimated:NO];
		self.selectionVC = nil;
	}
	
	
	// if we're in the list view, save that state
	if (self.displayingList) {
		[self.url setPath:@"list"
                    query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	} else {
		if (self.lastSearchText != nil && ![self.lastSearchText isEqualToString:@""] && self.mapView.currentAnnotation) {
			[self.url setPath:[NSString stringWithFormat:@"search/%@", [(MITMapSearchResultAnnotation*)self.mapView.currentAnnotation uniqueID]] query:self.lastSearchText];
			[self.url setAsModulePath];
			[self setURLPathUserLocation];
		}
	}
	self.view.hidden = NO;
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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
    self.url = nil;
	
	self.mapView.delegate = nil;
    self.mapView = nil;
    
    self.toolbar = nil;
    
	self.geoButton = nil;
    
	self.shuttleButton = nil;
    
	self.shuttleAnnotations = nil;
    
	self.searchResults = nil;
    self.hasSearchResults = NO;
    self.displayingList = NO;
	
    self.viewTypeButton = nil;
    self.searchResultsVC = nil;
    self.searchBar = nil;
	
    self.bookmarkButton = nil;
    self.selectionVC = nil;
    self.cancelSearchButton = nil;
    
}


-(void) setSearchResultsWithoutRecentering:(NSArray*)searchResults
{
    [self setSearchResults:searchResults
                  recenter:NO];
}

-(void) setSearchResults:(NSArray *)searchResults
{
    [self setSearchResults:searchResults
                  recenter:YES];
}

- (void)setSearchResults:(NSArray*)searchResults recenter:(BOOL)recenter
{
    self.searchFilter = nil;
	
	// remove search results
	[self.mapView removeAnnotations:self.searchResults];
	[self.mapView removeAnnotations:self.filteredSearchResults];
	_searchResults = searchResults;
	
	self.filteredSearchResults = nil;
	
	// remove any remaining annotations
	[self.mapView removeAllAnnotations:NO];
	
	if (nil != self.searchResultsVC) {
		self.searchResultsVC.searchResults = self.searchResults;
	}
	
	[self.mapView addAnnotations:self.searchResults];
    
    if (recenter && [self.searchResults count])
	{
        self.mapView.region = [self.mapView regionForAnnotations:searchResults];
		
		// turn off locate me
		self.geoButton.style = UIBarButtonItemStyleBordered;
		self.mapView.stayCenteredOnUserLocation = NO;
        [self saveRegion];
	}
	
}

-(MKCoordinateRegion)regionForAnnotations:(NSArray *) annotations {
	
	if (annotations.count > 0)
	{
		// determine the region for the search results
		double minLat = 90;
		double maxLat = -90;
		double minLon = 180;
		double maxLon = -180;
		
		for (id<MKAnnotation> annotation in annotations)
		{
			CLLocationCoordinate2D coordinate = annotation.coordinate;
			
			if (coordinate.latitude < minLat)
			{
				minLat = coordinate.latitude;
			}
			if (coordinate.latitude > maxLat )
			{
				maxLat = coordinate.latitude;
			}
			if (coordinate.longitude < minLon)
			{
				minLon = coordinate.longitude;
			}
			if(coordinate.longitude > maxLon)
			{
				maxLon = coordinate.longitude;
			}
			
		}
		
		CLLocationCoordinate2D center;
		center.latitude = minLat + (maxLat - minLat) / 2;
		center.longitude = minLon + (maxLon - minLon) / 2;
		
		// create the span and region with a little padding
		double latDelta = maxLat - minLat;
		double lonDelta = maxLon - minLon;
		
		if (latDelta < .002) latDelta = .002;
		if (lonDelta < .002) lonDelta = .002;
		
		MKCoordinateRegion region = MKCoordinateRegionMake(center, 	MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));
		
		// turn off locate me
		self.geoButton.style = UIBarButtonItemStyleBordered;
		self.mapView.stayCenteredOnUserLocation = NO;
		
		[self saveRegion];
		return region;
	}
	
	else {
		[self saveRegion];
		return MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
	}
    
}

#pragma mark ShuttleDataManagerDelegate

// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes
{
}

// message sent when stops were received. If request failed, this is called with a nil stops array
-(void) stopsReceived:(NSArray*) stops
{
	if (self.displayShuttles) {
		[self addAnnotationsForShuttleStops:stops];
	}
}

#pragma mark CampusMapViewController(Private)

-(void) addAnnotationsForShuttleStops:(NSArray*)shuttleStops
{
	if (self.shuttleAnnotations == nil) {
		self.shuttleAnnotations = [[NSMutableArray alloc] initWithCapacity:shuttleStops.count];
	}
	
	for (ShuttleStop* shuttleStop in shuttleStops)
	{
		ShuttleStopMapAnnotation* annotation = [[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop];
		[self.mapView addAnnotation:annotation];
		[self.shuttleAnnotations addObject:annotation];
	}
}

-(void) noSearchResultsAlert
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"Nothing found.", nil)
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
	alert.tag = kNoSearchResultsTag;
	alert.delegate = self;
	[alert show];
}

-(void) setURLPathUserLocation {
	NSMutableArray *components = [NSMutableArray arrayWithArray:[self.url.path componentsSeparatedByString:@"/"]];
	if (self.mapView.showsUserLocation && ![[components lastObject] isEqualToString:@"userLoc"]) {
		[self.url setPath:[NSString stringWithFormat:@"%@/%@", self.url.path, @"userLoc"] query:self.lastSearchText];
		[self.url setAsModulePath];
	}
	if (!self.mapView.showsUserLocation && [[components lastObject] isEqualToString:@"userLoc"]) {
		[self.url setPath:[self.url.path stringByReplacingOccurrencesOfString:@"userLoc" withString:@""] query:self.lastSearchText];
		[self.url setAsModulePath];
	}
}

-(void) saveRegion
{
	// save this region so we can use it on launch
	NSNumber* centerLat = [NSNumber numberWithDouble:self.mapView.region.center.latitude];
	NSNumber* centerLong = [NSNumber numberWithDouble:self.mapView.region.center.longitude];
	NSNumber* spanLat = [NSNumber numberWithDouble:self.mapView.region.span.latitudeDelta];
	NSNumber* spanLong = [NSNumber numberWithDouble:self.mapView.region.span.longitudeDelta];
	NSDictionary* regionDict = [NSDictionary dictionaryWithObjectsAndKeys:centerLat, @"centerLat", centerLong, @"centerLong", spanLat, @"spanLat", spanLong, @"spanLong", nil];
	
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* regionFilename = [docsFolder stringByAppendingPathComponent:@"region.plist"];
	[regionDict writeToFile:regionFilename atomically:YES];
}

#pragma mark UIAlertViewDelegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// if the alert view was "no search results", give focus back to the search bar
	if (alertView.tag == kNoSearchResultsTag) {
		[self.searchBar becomeFirstResponder];
	}
}


#pragma mark User actions

-(void) geoLocationTouched:(id)sender
{
    if ((self.userLocation == nil) && (self.mapView.showsUserLocation == NO)) {
        self.mapView.showsUserLocation = YES;
    } else if (self.userLocation) {
        CLLocationCoordinate2D center = self.userLocation.coordinate;
        self.mapView.region = MKCoordinateRegionMake(center, DEFAULT_MAP_SPAN);
    } else {
        // messages to be shown when user taps locate me button off campus
        NSString *message = nil;
        if (arc4random() & 1) {
            message = NSLocalizedString(@"Off Campus Warning 1", nil);
        } else {
            message = NSLocalizedString(@"Off Campus Warning 2", nil);
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Off Campus", nil)
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        
        self.mapView.showsUserLocation = NO; // turn off location updating
    }
    
	[self setURLPathUserLocation];
}

-(void) showListView:(BOOL)showList
{
    
	if (showList) {
		// if we are not already showing the list, do all this
		if (!self.displayingList) {
			// show the list.
			if(nil == self.searchResultsVC)
			{
				self.searchResultsVC = [[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC" bundle:nil];
				self.searchResultsVC.title = @"Campus Map";
				self.searchResultsVC.campusMapVC = self;
			}
			
			self.searchResultsVC.searchResults = self.searchResults;
			self.searchResultsVC.view.frame = self.mapView.frame;
            
			[self.view addSubview:self.searchResultsVC.view];
			
			[self.url setPath:@"list" query:self.lastSearchText];
			[self.url setAsModulePath];
			[self setURLPathUserLocation];

		}
	}
	else {
		// if we're not already showing the map
		if (self.displayingList) {
			// show the map, by hiding the list.
			[self.searchResultsVC.view removeFromSuperview];
			self.searchResultsVC = nil;
			
		}
        
        
		// only let the user switch to the list view if there are search results.
		if (self.lastSearchText != nil &&
            ![self.lastSearchText isEqualToString:@""] &&
            self.mapView.currentAnnotation)
        {
			[self.url setPath:[NSString stringWithFormat:@"search/%@", [(MITMapSearchResultAnnotation*)self.mapView.currentAnnotation uniqueID]]
                        query:self.lastSearchText];
        }
		else {
			[self.url setPath:@"" query:nil];
        }
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
	
    
    BOOL isDisplayingList = self.displayingList;
	self.displayingList = showList;
    
    if (isDisplayingList != showList) {
        [self layoutSearchBarViewWithEditing:NO
                                    animated:NO];
    }
    
}

-(void) viewTypeChanged:(id)sender
{
	// resign the search bar, if it was first selector
	[self.searchBar resignFirstResponder];
	
	// if there is nothing in the search bar, we are browsing categories; otherwise go to list view
	if (!self.displayingList && !self.hasSearchResults) {
		if(nil != self.selectionVC)
		{
			[self.selectionVC dismissModalViewControllerAnimated:NO];
			self.selectionVC = nil;
		}
		
		self.selectionVC = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBrowse
                                                                                        campusMap:self];
        
		[MITAppDelegate() presentAppModalViewController:self.selectionVC animated:YES];
	} else {
		[self showListView:!self.displayingList];
	}
	
}

-(void) receivedNewSearchResults:(NSArray*)searchResults forQuery:(NSString *)searchQuery
{
	
	NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:searchResults.count];
	
	for (NSDictionary* info in searchResults)
	{
		MITMapSearchResultAnnotation* annotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:info];
		[searchResultsArr addObject:annotation];
	}
	
	// this will remove old annotations and add the new ones.
	self.searchResults = searchResultsArr;
	
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* searchResultsFilename = [docsFolder stringByAppendingPathComponent:@"searchResults.plist"];
	[searchResults writeToFile:searchResultsFilename atomically:YES];
	[[NSUserDefaults standardUserDefaults] setObject:searchQuery forKey:CachedMapSearchQueryKey];
    
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self layoutSearchBarViewWithEditing:YES
                                animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self layoutSearchBarViewWithEditing:NO
                                animated:YES];
}

- (void)layoutSearchBarViewWithEditing:(BOOL)editing
                              animated:(BOOL)animated
{
    if (editing) {
        CGPoint animationOrigin = CGPointMake(kSearchBarWidth, CGRectGetMinY(self.searchBarView.frame));
        
        CGRect cancelRect = self.cancelToolbar.frame;
        cancelRect.origin = animationOrigin;
        self.cancelToolbar.frame = cancelRect;
        self.searchBar.showsBookmarkButton = NO;
        
        [UIView animateWithDuration:(animated ? 0.4 : 0.0)
                              delay: 0.0
                            options:(UIViewAnimationOptionCurveEaseOut |
                                     UIViewAnimationOptionLayoutSubviews)
                         animations:^{
                             CGRect toolbarFrame = self.geoToolbar.frame;
                             toolbarFrame.origin = animationOrigin;
                             
                             CGRect searchFrame = CGRectMake(CGRectGetMinX(self.searchBarView.bounds),
                                                             CGRectGetMinY(self.searchBarView.bounds),
                                                             CGRectGetWidth(self.searchBarView.frame) - CGRectGetWidth(self.cancelToolbar.frame),
                                                             CGRectGetHeight(self.searchBarView.frame));
                             
                             CGRect cancelFrame = self.cancelToolbar.frame;
                             cancelFrame.origin = CGPointMake(CGRectGetMaxX(searchFrame),
                                                              CGRectGetMinY(searchFrame));
                             
                             
                             self.searchBar.frame = searchFrame;
                             
                             self.geoToolbar.alpha = 1.0;
                             self.geoToolbar.frame = toolbarFrame;
                             self.geoToolbar.alpha = 0.0;
                             
                             self.cancelToolbar.alpha = 0.0;
                             [self.searchBarView addSubview:self.cancelToolbar];
                             self.cancelToolbar.frame = cancelFrame;
                             self.cancelToolbar.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             self.toolbar = self.cancelToolbar;
                             [self.geoToolbar removeFromSuperview];
                         }];
    } else {
        CGPoint animationOrigin = CGPointMake(kSearchBarWidth, CGRectGetMinY(self.searchBarView.frame));
        CGRect searchFrame = CGRectMake(CGRectGetMinX(self.searchBarView.bounds),
                                        CGRectGetMinY(self.searchBarView.bounds),
                                        CGRectGetWidth(self.searchBarView.frame) - CGRectGetWidth(self.geoToolbar.frame),
                                        CGRectGetHeight(self.searchBarView.frame));
        
        CGRect geoFrame = self.geoToolbar.frame;
        geoFrame.origin = animationOrigin;
        self.geoToolbar.frame = geoFrame;
        
        if (!self.displayingList) {
            [self.searchBarView addSubview:self.geoToolbar];
        } else {
            searchFrame.size.width = CGRectGetWidth(self.searchBarView.frame);
        }
        
        [UIView animateWithDuration:(animated ? 0.4 : 0.0)
                              delay:0.0
                            options:(UIViewAnimationOptionCurveEaseOut |
                                     UIViewAnimationOptionLayoutSubviews)
                         animations:^{
                             CGRect cancelFrame = self.cancelToolbar.frame;
                             cancelFrame.origin = animationOrigin;
                             
                             CGRect geoToolbarFrame = self.geoToolbar.frame;
                             geoToolbarFrame.origin = CGPointMake(CGRectGetMaxX(searchFrame),
                                                                  CGRectGetMinY(searchFrame));
                             
                             
                             self.cancelToolbar.alpha = 1.0;
                             self.cancelToolbar.frame = cancelFrame;
                             self.cancelToolbar.alpha = 0.0;
                             
                             self.geoToolbar.alpha = 0.0;
                             self.geoToolbar.frame = geoToolbarFrame;
                             self.geoToolbar.alpha = 1.0;
                             
                             self.searchBar.frame = searchFrame;
                         }
                         completion:^(BOOL finished) {
                             [self.cancelToolbar removeFromSuperview];
                             self.cancelToolbar.alpha = 1.0;
                             
                             self.toolbar = self.geoToolbar;
                             self.searchBar.showsBookmarkButton = YES;
                         }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	
	// delete any previous instance of this search term
	MapSearch* mapSearch = [CoreDataManager getObjectForEntity:CampusMapSearchEntityName attribute:@"searchTerm" value:searchBar.text];
	if(nil != mapSearch)
	{
		[CoreDataManager deleteObject:mapSearch];
	}
	
	// insert the new instance of this search term
	mapSearch = [CoreDataManager insertNewObjectForEntityForName:CampusMapSearchEntityName];
	mapSearch.searchTerm = searchBar.text;
	mapSearch.date = [NSDate date];
	[CoreDataManager saveData];
	
	
	// determine if we are past our max search limit. If so, trim an item
	NSError* error = nil;
	
	NSFetchRequest* countFetchRequest = [[NSFetchRequest alloc] initWithEntityName:CampusMapSearchEntityName];
	NSUInteger count = 	[[CoreDataManager managedObjectContext] countForFetchRequest:countFetchRequest
                                                                               error:&error];
	
	// cap the number of previous searches maintained in the DB. If we go over the limit, delete one.
	if(nil == error && count > kPreviousSearchLimit)
	{
		// get the oldest item
		NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSFetchRequest* limitFetchRequest = [[NSFetchRequest alloc] initWithEntityName:CampusMapSearchEntityName];
		[limitFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[limitFetchRequest setFetchLimit:1];
		NSArray* overLimit = [[CoreDataManager managedObjectContext] executeFetchRequest:limitFetchRequest
                                                                                   error:nil];
        
		if(overLimit && overLimit.count == 1)
		{
			[[CoreDataManager managedObjectContext] deleteObject:[overLimit objectAtIndex:0]];
		}
        
		[CoreDataManager saveData];
	}
	
	// ask the campus map view controller to perform the search
	[self search:searchBar.text];
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	self.hasSearchResults = NO;
	[searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	// clear search result if search string becomes empty
	if (searchText.length == 0 ) {
		self.hasSearchResults = NO;
		// tell the campus view controller to remove its search results.
		[self search:nil];
	}
}

-(void) touchEnded
{
	[self.searchBar resignFirstResponder];
}

-(void) cancelSearch
{
	[self.searchBar resignFirstResponder];
}

#pragma mark Custom Bookmark Button Functionality
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
	if(nil != self.selectionVC)
	{
		[self.selectionVC dismissModalViewControllerAnimated:NO];
		self.selectionVC = nil;
	}
	
	self.selectionVC = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBookmarks campusMap:self];
	[MITAppDelegate() presentAppModalViewController:_selectionVC animated:YES];
}

#pragma mark MITMapViewDelegate

-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
	[self setURLPathUserLocation];
	
	[self saveRegion];
}

- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
	[self setURLPathUserLocation];
}

-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated
{
	// determine the type of the annotation. If it is a search result annotation, display the details
	if ([annotation isKindOfClass:[MITMapSearchResultAnnotation class]])
	{
		
		// push the details page onto the stack for the item selected.
		MITMapDetailViewController* detailsVC = [[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
                                                                                             bundle:nil];
		
		detailsVC.annotation = annotation;
		detailsVC.title = @"Info";
		detailsVC.campusMapVC = self;
		
		if(!((MITMapSearchResultAnnotation*)annotation).bookmark)
		{
            
			if(self.lastSearchText != nil && self.lastSearchText.length > 0)
			{
				detailsVC.queryText = self.lastSearchText;
			}
		}
		[self.navigationController pushViewController:detailsVC animated:animated];
	}
	
	else if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]])
	{
		
		// move this logic to the shuttle module
		ShuttleStopViewController* shuttleStopVC = [[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)annotation shuttleStop];
		[self.navigationController pushViewController:shuttleStopVC animated:animated];
		
	}
	if ([annotation class] == [MITMapSearchResultAnnotation class]) {
		MITMapSearchResultAnnotation* theAnnotation = (MITMapSearchResultAnnotation*)annotation;
		if (self.displayingList)
			[self.url setPath:[NSString stringWithFormat:@"list/detail/%@", theAnnotation.uniqueID] query:self.lastSearchText];
		else
			[self.url setPath:[NSString stringWithFormat:@"detail/%@", theAnnotation.uniqueID] query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
}

// a callout accessory control was tapped.
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view
{
	[self pushAnnotationDetails:view.annotation animated:YES];
}

- (void)mapView:(MITMapView *)mapView wasTouched:(CGPoint)screenPoint
{
	[self.searchBar resignFirstResponder];
}

- (void)mapView:(MITMapView *)mapView annotationSelected:(id<MKAnnotation>)annotation {
	if([annotation isKindOfClass:[MITMapSearchResultAnnotation class]])
	{
		MITMapSearchResultAnnotation* searchAnnotation = (MITMapSearchResultAnnotation*)annotation;
		// if the annotation is not fully loaded, try to load it
		if (!searchAnnotation.dataPopulated)
		{
			[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchAnnotation.bldgnum
                                                          jsonDelegate:self
                                                                object:annotation];
		}
		[self.url setPath:[NSString stringWithFormat:@"search/%@", searchAnnotation.uniqueID] query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
}

-(void) locateUserFailed:(MITMapView *)mapView
{
	if (self.mapView.stayCenteredOnUserLocation)
	{
		[self.geoButton setStyle:UIBarButtonItemStyleBordered];
	}
}

- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)userLocation {
    CLLocation *oldLocation = self.userLocation;
    
    if ([userLocation isNearCampus]) {
        self.userLocation = userLocation;
    }
    
    if (oldLocation == nil) {
        [self geoLocationTouched:nil];
    }
}

#pragma mark JSONLoadedDelegate

- (void) request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{
	NSArray *searchResults = JSONObject;
	if ([request.userData isKindOfClass:[NSString class]]) {
		NSString *searchType = request.userData;
        
		if ([searchType isEqualToString:kAPISearch])
		{
			self.lastSearchText = [request.parameters objectForKey:@"q"];
            
			[self receivedNewSearchResults:searchResults forQuery:self.lastSearchText];
            
			// if there were no search results, tell the user about it.
			if(nil == searchResults || searchResults.count <= 0) {
				[self noSearchResultsAlert];
				self.hasSearchResults = NO;
			} else {
				self.hasSearchResults = YES;
			}
		}
	}
    
	
	else if([request.userData isKindOfClass:[MITMapSearchResultAnnotation class]]) {
		// updating an annotation search request
		MITMapSearchResultAnnotation* oldAnnotation = request.userData;
		NSArray* results = JSONObject;
		
		if (results.count > 0)
		{
			MITMapSearchResultAnnotation* newAnnotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:[results objectAtIndex:0]];
			
			BOOL isViewingAnnotation = (self.mapView.currentAnnotation == oldAnnotation);
			
			[self.mapView removeAnnotation:oldAnnotation];
			[self.mapView addAnnotation:newAnnotation];
			
			if (isViewingAnnotation) {
				[self.mapView selectAnnotation:newAnnotation animated:NO withRecenter:NO];
			}
			self.hasSearchResults = YES;
		} else {
			self.hasSearchResults = NO;
		}
	}
}

// there was an error connecting to the specified URL.
- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return ([(NSString *)request.userData isEqualToString:kAPISearch]);
}

- (NSString *) request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Campus Map";
}

#pragma mark UITableViewDataSource

-(void) search:(NSString*)searchText
{
	if (nil == searchText)
	{
		self.searchResults = nil;
		self.lastSearchText = nil;
	}
	else
	{
		[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchText
                                                      jsonDelegate:self
                                                            object:kAPISearch];
	}
	if (self.displayingList)
		[self.url setPath:@"list" query:searchText];
	else if (searchText != nil && ![searchText isEqualToString:@""])
		[self.url setPath:@"search" query:searchText];
	else 
		[self.url setPath:@"" query:nil];
	[self.url setAsModulePath];
	[self setURLPathUserLocation];
}


@end
