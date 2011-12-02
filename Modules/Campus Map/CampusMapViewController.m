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

#define kSearchBarWidth 270
#define kSearchBarCancelWidthDiff 28

#define kAPISearch		@"Search"

#define kNoSearchResultsTag 31678

#define kPreviousSearchLimit 25


@interface CampusMapViewController(Private)

- (void)updateMapListButton;
- (void)addAnnotationsForShuttleStops:(NSArray*)shuttleStops;
- (void)noSearchResultsAlert;
- (void)saveRegion; // a convenience method for saving the mapView's current region (for saving state)

@end

@implementation CampusMapViewController
@synthesize geoButton = _geoButton;
@synthesize searchResults = _searchResults;
@synthesize mapView = _mapView;
@synthesize lastSearchText = _lastSearchText;
@synthesize hasSearchResults = _hasSearchResults;
@synthesize displayingList = _displayingList;
@synthesize searchBar = _searchBar;
@synthesize url;
@synthesize campusMapModule = _campusMapModule;
@synthesize userLocation = _userLocation;

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	// create our own view
	self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 364)] autorelease];
	
	_viewTypeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Browse" style:UIBarButtonItemStylePlain target:self action:@selector(viewTypeChanged:)] autorelease];
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	// add a search bar to our view
	_searchBar = [[ UISearchBar alloc] initWithFrame:CGRectMake(0, 0, kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
	[_searchBar setDelegate:self];
	_searchBar.placeholder = NSLocalizedString(@"Search MIT Campus", nil);
	_searchBar.translucent = NO;
	_searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	_searchBar.showsBookmarkButton = NO; // we'll be adding a custom bookmark button
	[self.view addSubview:_searchBar];
		
	// create the map view controller and its view to our view. 
	_mapView = [[MITMapView alloc] initWithFrame: CGRectMake(0, _searchBar.frame.size.height, 320, self.view.frame.size.height - _searchBar.frame.size.height)];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[_mapView setRegion:MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN)];
	[self.view addSubview:_mapView];
	_mapView.delegate = self;
    [_mapView fixateOnCampus];
	
	// add the rest of the toolbar to which we can add buttons
	_toolBar = [[CampusMapToolbar alloc] initWithFrame:CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
	_toolBar.translucent = NO;
	_toolBar.tintColor = SEARCH_BAR_TINT_COLOR;
	[self.view addSubview:_toolBar];
	
	// create toolbar button item for geolocation  
	UIImage* image = [UIImage imageNamed:@"map/map_button_icon_locate.png"];
	_geoButton = [[UIBarButtonItem alloc] initWithImage:image
												  style:UIBarButtonItemStyleBordered
												 target:self
												 action:@selector(geoLocationTouched:)];
	_geoButton.width = image.size.width + 10;

	[_toolBar setItems:[NSArray arrayWithObjects:_geoButton, nil]];
	
	// add our own bookmark button item since we are not using the default
	// bookmark button of the UISearchBar
	_bookmarkButton = [[UIButton alloc] initWithFrame:CGRectMake(231, 8, 32, 28)];
	[_bookmarkButton setImage:[UIImage imageNamed:@"map/searchfield_star.png"] forState:UIControlStateNormal];
	[self.view addSubview:_bookmarkButton];
	[_bookmarkButton addTarget:self action:@selector(bookmarkButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	
	url = [[MITModuleURL alloc] initWithTag:CampusMapTag];
	
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
    self.mapView.showsUserLocation = YES;
    
    [self updateMapListButton];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.mapView removeTileOverlay];
    self.mapView.showsUserLocation = NO;
}

-(void) viewDidAppear:(BOOL)animated
{
	// show the annotations
	
	[super viewDidAppear:animated];
	
	// if there is a bookmarks view controller hanging around, dismiss and release it. 
	if(nil != _selectionVC)
	{
		[_selectionVC dismissModalViewControllerAnimated:NO];
		[_selectionVC release];
		_selectionVC = nil;
	}
	
	
	// if we're in the list view, save that state
	if (self.displayingList) {
		[url setPath:[NSString stringWithFormat:@"list", [(MITMapSearchResultAnnotation*)_mapView.currentAnnotation uniqueID]] query:_lastSearchText];
		[url setAsModulePath];
		[self setURLPathUserLocation];
	} else {
		if (_lastSearchText != nil && ![_lastSearchText isEqualToString:@""] && _mapView.currentAnnotation) {
			[url setPath:[NSString stringWithFormat:@"search/%@", [(MITMapSearchResultAnnotation*)_mapView.currentAnnotation uniqueID]] query:_lastSearchText];
			[url setAsModulePath];
			[self setURLPathUserLocation];
		}
	}
	self.view.hidden = NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	[url release];
    url = nil;
	
	_mapView.delegate = nil;
	[_mapView release];
    _mapView = nil;
    
	[_toolBar release];
    _toolBar = nil;
    
	[_geoButton release];
	_geoButton = nil;
    
	[_shuttleButton release];
	_shuttleButton = nil;
    
	[_shuttleAnnotations release];
	_shuttleAnnotations = nil;
    
	[_searchResults release];
	_searchResults = nil;
    self.hasSearchResults = NO;
    self.displayingList = NO;
	
	[_viewTypeButton release];
    _viewTypeButton = nil;
	[_searchResultsVC release];
    _searchResultsVC = nil;
	[_searchBar release];
    _searchBar = nil;
	
	[_bookmarkButton release];
    _bookmarkButton = nil;
	[_selectionVC release];
    _selectionVC = nil;
	[_cancelSearchButton release];
    _cancelSearchButton = nil;

}


- (void)dealloc 
{
	[super dealloc];
}

-(void) setSearchResultsWithoutRecentering:(NSArray*)searchResults
{
	_searchFilter = nil;
	
	// remove search results
	[_mapView removeAnnotations:_searchResults];
	[_mapView removeAnnotations:_filteredSearchResults];
	[_searchResults release];
	_searchResults = [searchResults retain];
	
	[_filteredSearchResults release];
	_filteredSearchResults = nil;
	
	// remove any remaining annotations
	[_mapView removeAllAnnotations:NO];
	
	if (nil != _searchResultsVC) {
		_searchResultsVC.searchResults = _searchResults;
	}
	
	[_mapView addAnnotations:_searchResults];
}

-(void) setSearchResults:(NSArray *)searchResults
{
	[self setSearchResultsWithoutRecentering:searchResults];
	
	if (_searchResults.count > 0) 
	{
		// determine the region for the search results
		double minLat = 90;
		double maxLat = -90;
		double minLon = 180;
		double maxLon = -180;
		
		for (id<MKAnnotation> annotation in _searchResults) 
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
		/*if (_mapView.stayCenteredOnUserLocation) {
			if ([_mapView.userLocation coordinate].latitude < minLat)
				minLat = [_mapView.userLocation coordinate].latitude;
			if ([_mapView.userLocation coordinate].latitude > maxLat)
				maxLat = [_mapView.userLocation coordinate].latitude;
			if ([_mapView.userLocation coordinate].longitude < minLon)
				minLon = [_mapView.userLocation coordinate].longitude;
			if ([_mapView.userLocation coordinate].longitude > maxLon)
				maxLon = [_mapView.userLocation coordinate].longitude;
		}*/
		
		CLLocationCoordinate2D center;
		center.latitude = minLat + (maxLat - minLat) / 2;
		center.longitude = minLon + (maxLon - minLon) / 2;
		
		// create the span and region with a little padding
		double latDelta = maxLat - minLat;
		double lonDelta = maxLon - minLon;
		
		if (latDelta < .002) latDelta = .002;
		if (lonDelta < .002) lonDelta = .002;
		
		MKCoordinateRegion region = MKCoordinateRegionMake(center, 	MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));
		
		_mapView.region = region;
		
		// turn off locate me
		_geoButton.style = UIBarButtonItemStyleBordered;
		_mapView.stayCenteredOnUserLocation = NO;
	}
	
	[self saveRegion];
}

-(void) setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter
{
	_searchFilter = filter;
	
	// if there was no filter, just add the annotations the normal way
	if(nil == filter)
	{
		[self setSearchResults:searchResults];
		return;
	}
	
	[_mapView removeAnnotations:_filteredSearchResults];
	[_mapView removeAnnotations:_searchResults];
	
	[_searchResults release];
	_searchResults = [searchResults retain];
	
	[_filteredSearchResults release];
	_filteredSearchResults = nil;
	
	
	// reformat the search results for the map. Combine items that are in common buildings into one annotation result.
	NSMutableDictionary* mapSearchResults = [NSMutableDictionary dictionaryWithCapacity:_searchResults.count];
	for (MITMapSearchResultAnnotation* annotation in _searchResults)
	{
		MITMapSearchResultAnnotation* previousAnnotation = [mapSearchResults objectForKey:[annotation performSelector:filter]];
		if (nil == previousAnnotation) {
			MITMapSearchResultAnnotation* newAnnotation = [[[MITMapSearchResultAnnotation alloc] initWithCoordinate:annotation.coordinate] autorelease];
			newAnnotation.bldgnum = annotation.bldgnum;
			[mapSearchResults setObject:newAnnotation forKey:[annotation performSelector:filter]];
		}
	}
	
	_filteredSearchResults = [[mapSearchResults allValues] retain];
	
	[_mapView addAnnotations:_filteredSearchResults];
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
		/*if (_mapView.stayCenteredOnUserLocation) {
		 if ([_mapView.userLocation coordinate].latitude < minLat)
		 minLat = [_mapView.userLocation coordinate].latitude;
		 if ([_mapView.userLocation coordinate].latitude > maxLat)
		 maxLat = [_mapView.userLocation coordinate].latitude;
		 if ([_mapView.userLocation coordinate].longitude < minLon)
		 minLon = [_mapView.userLocation coordinate].longitude;
		 if ([_mapView.userLocation coordinate].longitude > maxLon)
		 maxLon = [_mapView.userLocation coordinate].longitude;
		 }*/
		
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
		_geoButton.style = UIBarButtonItemStyleBordered;
		_mapView.stayCenteredOnUserLocation = NO;
		
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
	if (_displayShuttles) {
		[self addAnnotationsForShuttleStops:stops];
	}
}

#pragma mark CampusMapViewController(Private)

-(void) addAnnotationsForShuttleStops:(NSArray*)shuttleStops
{
	if (_shuttleAnnotations == nil) {
		_shuttleAnnotations = [[NSMutableArray alloc] initWithCapacity:shuttleStops.count];
	}
	
	for (ShuttleStop* shuttleStop in shuttleStops) 
	{
		ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
		[_mapView addAnnotation:annotation];
		[_shuttleAnnotations addObject:annotation];
	}
}

-(void) noSearchResultsAlert
{
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
													 message:NSLocalizedString(@"Nothing found.", nil)
													delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
	alert.tag = kNoSearchResultsTag;
	alert.delegate = self;
	[alert show];
}

-(void) setURLPathUserLocation {
	NSMutableArray *components = [NSMutableArray arrayWithArray:[url.path componentsSeparatedByString:@"/"]];
	if (_mapView.showsUserLocation && ![[components lastObject] isEqualToString:@"userLoc"]) {
		[url setPath:[NSString stringWithFormat:@"%@/%@", url.path, @"userLoc"] query:_lastSearchText];
		[url setAsModulePath];
	}
	if (!_mapView.showsUserLocation && [[components lastObject] isEqualToString:@"userLoc"]) {
		[url setPath:[url.path stringByReplacingOccurrencesOfString:@"userLoc" withString:@""] query:_lastSearchText];
		[url setAsModulePath];
	}
}

-(void) saveRegion
{	
	// save this region so we can use it on launch
	NSNumber* centerLat = [NSNumber numberWithDouble:_mapView.region.center.latitude];
	NSNumber* centerLong = [NSNumber numberWithDouble:_mapView.region.center.longitude];
	NSNumber* spanLat = [NSNumber numberWithDouble:_mapView.region.span.latitudeDelta];
	NSNumber* spanLong = [NSNumber numberWithDouble:_mapView.region.span.longitudeDelta];
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
		[_searchBar becomeFirstResponder];
	}
}


#pragma mark User actions

-(void) geoLocationTouched:(id)sender
{
    if (self.userLocation) {
        CLLocationCoordinate2D center = self.userLocation.coordinate;
        self.mapView.region = MKCoordinateRegionMake(center, DEFAULT_MAP_SPAN);
    }
    
    else {
        // messages to be shown when user taps locate me button off campus
        NSString *message = nil;
        if (arc4random() & 1) {
            message = NSLocalizedString(@"Off Campus Warning 1", nil);
        } else {
            message = NSLocalizedString(@"Off Campus Warning 2", nil); 
        }
        
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Off Campus", nil)
                                                         message:message 
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                               otherButtonTitles:nil] autorelease];
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
			if(nil == _searchResultsVC)
			{
				_searchResultsVC = [[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC" bundle:nil];
				_searchResultsVC.title = @"Campus Map";
				_searchResultsVC.campusMapVC = self;
			}
			
			_searchResultsVC.searchResults = _searchResults;
			_searchResultsVC.view.frame = _mapView.frame;
						
			[self.view addSubview:_searchResultsVC.view];
			
			// hide the toolbar and stretch the search bar
			_toolBar.items = nil;
			_toolBar.frame =  CGRectMake(kSearchBarWidth, 0, 0, NAVIGATION_BAR_HEIGHT);
			_searchBar.frame = CGRectMake(_searchBar.frame.origin.x, 
										  _searchBar.frame.origin.y,
										  self.view.frame.size.width,
										  _searchBar.frame.size.height);
			_bookmarkButton.frame = CGRectMake(281, 8, 32, 28);
			
			[url setPath:@"list" query:_lastSearchText];
			[url setAsModulePath];
			[self setURLPathUserLocation];
		}
	}
	else {
		// if we're not already showing the map
		if (self.displayingList) {
			// show the map, by hiding the list. 
			[_searchResultsVC.view removeFromSuperview];
			[_searchResultsVC release];
			_searchResultsVC = nil;
			
			// show the toolbar and shrink the search bar. 
			_toolBar.frame =  CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
			_toolBar.items = [NSArray arrayWithObject:_geoButton];
			_searchBar.frame = CGRectMake(_searchBar.frame.origin.x, 
										  _searchBar.frame.origin.y,
										  kSearchBarWidth,
										  _searchBar.frame.size.height);
			_bookmarkButton.frame = CGRectMake(231, 8, 32, 28);
		}
	
		// only let the user switch to the list view if there are search results. 
		if (_lastSearchText != nil 
        && ![_lastSearchText isEqualToString:@""] 
        && _mapView.currentAnnotation) {
			[url setPath:[NSString stringWithFormat:@"search/%@", [(MITMapSearchResultAnnotation*)_mapView.currentAnnotation uniqueID]] query:_lastSearchText];
        }
		else {
			[url setPath:@"" query:nil];
        }
		[url setAsModulePath];
		[self setURLPathUserLocation];
	}
	
	self.displayingList = showList;
}

-(void) viewTypeChanged:(id)sender
{
	// resign the search bar, if it was first selector
	[_searchBar resignFirstResponder];
	
	// if there is nothing in the search bar, we are browsing categories; otherwise go to list view
	if (!self.displayingList && !self.hasSearchResults) {
		if(nil != _selectionVC)
		{
			[_selectionVC dismissModalViewControllerAnimated:NO];
			[_selectionVC release];
			_selectionVC = nil;
		}
		
		_selectionVC = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBrowse campusMap:self];
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:_selectionVC animated:YES];
	} else {	
		[self showListView:!self.displayingList];
	}
	
}

-(void) receivedNewSearchResults:(NSArray*)searchResults forQuery:(NSString *)searchQuery
{
	
	NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:searchResults.count];
	
	for (NSDictionary* info in searchResults)
	{
		MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:info] autorelease];
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
	_bookmarkButton.hidden = YES;
	
	// Add the cancel button, and remove the geo button. 
	_cancelSearchButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSearch)];
	
	if (self.displayingList) {
		_toolBar.frame = CGRectMake(320, 0, 320 - kSearchBarWidth + kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	}
	
	[UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.3];
	_searchBar.frame = CGRectMake(0, 0, kSearchBarWidth - kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	[_searchBar layoutSubviews];
	_bookmarkButton.frame = CGRectMake(231 - kSearchBarCancelWidthDiff, 8, 32, 28);
	[_toolBar setItems:[NSArray arrayWithObjects:_cancelSearchButton, nil]];
	_toolBar.frame = CGRectMake(kSearchBarWidth - kSearchBarCancelWidthDiff, 0, 320 - kSearchBarWidth + kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	[UIView commitAnimations];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	// when we're not editing, make sure the bookmark button is put back
	_bookmarkButton.hidden = NO;
	
	// remove the cancel button and add the geo button back. 
	[_cancelSearchButton release];
	_cancelSearchButton = nil;
	
	
	[UIView beginAnimations:@"doneSearching" context:nil];
	_searchBar.frame = CGRectMake(0, 0, self.displayingList ? self.view.frame.size.width : kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
	[_searchBar layoutSubviews];
	[_toolBar setItems:[NSArray arrayWithObjects:self.displayingList ? nil : _geoButton , nil]];
	_toolBar.frame = CGRectMake( self.displayingList ? 320 : kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
	_bookmarkButton.frame = self.displayingList ? CGRectMake(281, 8, 32, 28) : CGRectMake(231, 8, 32, 28);

	[UIView commitAnimations];
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
	
	NSFetchRequest* countFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[countFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName inManagedObjectContext:[CoreDataManager managedObjectContext]]];
	NSUInteger count = 	[[CoreDataManager managedObjectContext] countForFetchRequest:countFetchRequest error:&error];
	
	// cap the number of previous searches maintained in the DB. If we go over the limit, delete one. 
	if(nil == error && count > kPreviousSearchLimit)
	{
		// get the oldest item
		NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
		NSFetchRequest* limitFetchRequest = [[[NSFetchRequest alloc] init] autorelease];		
		[limitFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[limitFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName inManagedObjectContext:[CoreDataManager managedObjectContext]]];
		[limitFetchRequest setFetchLimit:1];
		NSArray* overLimit = [[CoreDataManager managedObjectContext] executeFetchRequest: limitFetchRequest error:nil];
		 
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
	[_searchBar resignFirstResponder];
}

-(void) cancelSearch
{
	[_searchBar resignFirstResponder];
}

#pragma mark Custom Bookmark Button Functionality

- (void)bookmarkButtonClicked:(UIButton *)sender
{
	if(nil != _selectionVC)
	{
		[_selectionVC dismissModalViewControllerAnimated:NO];
		[_selectionVC release];
		_selectionVC = nil;
	}
	
	_selectionVC = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBookmarks campusMap:self];
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate presentAppModalViewController:_selectionVC animated:YES];
}

#pragma mark MITMapViewDelegate

-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
	[self setURLPathUserLocation];
	
	[self saveRegion];
}

- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
	//_geoButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	
	[self setURLPathUserLocation];
}

-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated
{
	// determine the type of the annotation. If it is a search result annotation, display the details
	if ([annotation isKindOfClass:[MITMapSearchResultAnnotation class]]) 
	{
		
		// push the details page onto the stack for the item selected. 
		MITMapDetailViewController* detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
																							  bundle:nil] autorelease];
		
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
		ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)annotation shuttleStop];
		[self.navigationController pushViewController:shuttleStopVC animated:animated];
		
	}
	if ([annotation class] == [MITMapSearchResultAnnotation class]) {
		MITMapSearchResultAnnotation* theAnnotation = (MITMapSearchResultAnnotation*)annotation;
		if (self.displayingList)
			[url setPath:[NSString stringWithFormat:@"list/detail/%@", theAnnotation.uniqueID] query:_lastSearchText];
		else 
			[url setPath:[NSString stringWithFormat:@"detail/%@", theAnnotation.uniqueID] query:_lastSearchText];
		[url setAsModulePath];
		[self setURLPathUserLocation];
	}	
}

// a callout accessory control was tapped. 
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view 
{
	[self pushAnnotationDetails:view.annotation animated:YES];
}

- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch
{
	[_searchBar resignFirstResponder];
}

- (void)mapView:(MITMapView *)mapView annotationSelected:(id<MKAnnotation>)annotation {
	if([annotation isKindOfClass:[MITMapSearchResultAnnotation class]])
	{
		MITMapSearchResultAnnotation* searchAnnotation = (MITMapSearchResultAnnotation*)annotation;
		// if the annotation is not fully loaded, try to load it
		if (!searchAnnotation.dataPopulated) 
		{	
			[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchAnnotation.bldgnum jsonDelegate:self object:annotation];	
		}
		[url setPath:[NSString stringWithFormat:@"search/%@", searchAnnotation.uniqueID] query:_lastSearchText];
		[url setAsModulePath];
		[self setURLPathUserLocation];
	}
}

-(void) locateUserFailed:(MITMapView *)mapView
{
	if (_mapView.stayCenteredOnUserLocation) 
	{
		[_geoButton setStyle:UIBarButtonItemStyleBordered];
	}	
}

- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)userLocation {

    if ([userLocation isNearCampus]) {
        self.userLocation = userLocation;
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
		
			[_lastSearchText release];
			_lastSearchText = [[request.params objectForKey:@"q"] retain];
		
			[self receivedNewSearchResults:searchResults forQuery:_lastSearchText];
		
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
			MITMapSearchResultAnnotation* newAnnotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:[results objectAtIndex:0]] autorelease];
			
			BOOL isViewingAnnotation = (_mapView.currentAnnotation == oldAnnotation);
			
			[_mapView removeAnnotation:oldAnnotation];
			[_mapView addAnnotation:newAnnotation];
			
			if (isViewingAnnotation) {
				[_mapView selectAnnotation:newAnnotation animated:NO withRecenter:NO];
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

		[_lastSearchText release];
		_lastSearchText = nil;
		
		/*
		[_mapView removeAnnotations:_searchResults];
		[_searchResults release];
		_searchResults = nil;
		[_lastSearchText release];
		_lastSearchText = nil;

		if (nil != _searchResultsVC) {
			_searchResultsVC.searchResults = nil;
			
		}
		 */
	}
	else
	{		
		[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchText jsonDelegate:self object:kAPISearch];
	}
	if (self.displayingList)
		[url setPath:@"list" query:searchText];
	else if (searchText != nil && ![searchText isEqualToString:@""])
		[url setPath:@"search" query:searchText];
	else 
		[url setPath:@"" query:nil];
	[url setAsModulePath];
	[self setURLPathUserLocation];
}


@end
