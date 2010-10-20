#import "CampusMapViewController.h"
#import "NSString+SBJSON.h"
#import "MITMapSearchResultAnnotation.h"
#import "MITMapCategory.h"
#import "CategoriesViewController.h"
#import "MITMapSearchResultsVC.h"
#import "MITMapDetailViewController.h"
#import "ShuttleDataManager.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "MITUIConstants.h"

#define kSearchBarWidth 270
#define kAPISearch		@"Search"
#define kAPICategories	@"Categories"

#define kNoSearchResultsTag 31678
#define kErrorConnectingTag 31679

@interface CampusMapViewController(Private)

-(void) addAnnotationsForShuttleStops:(NSArray*)shuttleStops;

-(void) noSearchResultsAlert;

-(void) errorConnectingAlert;

@end

@implementation CampusMapViewController
@synthesize searchResults = _searchResults;
@synthesize selectedCategory = _selectedCategory;
@synthesize mapView = _mapView;
@synthesize lastSearchText = _lastSearchText;
@synthesize searchBar = _searchBar;

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	
	// create our own view
	self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 364)] autorelease];
	
	_viewTypeButton = [[[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStylePlain target:self action:@selector(viewTypeChanged:)] autorelease];
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	// add a search bar to our view
	_searchBar = [[ UISearchBar alloc] initWithFrame:CGRectMake(0, 0, kSearchBarWidth, 44)];
	[_searchBar setDelegate:self];
	_searchBar.placeholder = NSLocalizedString(@"Search MIT Campus Map", nil);
	_searchBar.translucent = NO;
	_searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	[self.view addSubview:_searchBar];
		
	// create the map view controller and its view to our view. 
	_mapView = [[MITMapView alloc] initWithFrame: CGRectMake(0, _searchBar.frame.size.height, 320, self.view.frame.size.height - _searchBar.frame.size.height)];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:_mapView];
	_mapView.delegate = self;
	
	// add the rest of the toolbar to which we can add buttons
	_toolBar = [[CampusMapToolbar alloc] initWithFrame:CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, 44)];
	_toolBar.translucent = NO;
	_toolBar.tintColor = SEARCH_BAR_TINT_COLOR;
	[self.view addSubview:_toolBar];
	
	// create toolbar button item for geolocation  
	UIImage* image = [UIImage imageNamed:@"map_button_icon_locate.png"];
	_geoButton = [[UIBarButtonItem alloc] initWithImage:image
												  style:UIBarButtonItemStyleBordered
												 target:self
												 action:@selector(geoLocationTouched:)];
	_geoButton.width = image.size.width + 10;

	/*
	_shuttleButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map_button_shuttle.png"]
													  style:UIBarButtonItemStyleBordered
													 target:self
													 action:@selector(shuttleButtonTouched:)];
	_shuttleButton.width = image.size.width + 10;
	[_toolBar setItems:[NSArray arrayWithObjects:_geoButton, _shuttleButton, nil]];
	*/
	[_toolBar setItems:[NSArray arrayWithObjects:_geoButton, nil]];
	
	// register for shuttle notifications
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {

	
	[super viewDidLoad];
	
	/*
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"mapCenterLat"] != nil) {
		CLLocationCoordinate2D center;
		center.latitude = [[defaults objectForKey:@"mapCenterLat"] doubleValue];
		center.longitude = [[defaults objectForKey:@"mapCenterLon"] doubleValue];
		
		MKCoordinateRegion region = MKCoordinateRegionMake(center, 
														   MKCoordinateSpanMake([[defaults objectForKey:@"mapLatDelta"] doubleValue],
																				[[defaults objectForKey:@"mapLonDelta"] doubleValue]));
		_mapView.region = region;
	}
	*/
	
	// turn on the location dot
	_mapView.showsUserLocation = YES;
}

-(void) hideAnnotations:(BOOL)hide
{
	for (id<MKAnnotation> annotation in _searchResults) {
		MITMapAnnotationView* annotationView = [_mapView viewForAnnotation:annotation];
		[annotationView setHidden:hide];
	}
	
	for (id<MKAnnotation> annotation in _filteredSearchResults) {
		MITMapAnnotationView* annotationView = [_mapView viewForAnnotation:annotation];
		[annotationView setHidden:hide];		
	}
}

-(void) viewWillAppear:(BOOL)animated
{

}

-(void) viewWillDisappear:(BOOL)animated
{
	// hide the annotations
	//[self hideAnnotations:YES];
}

-(void) viewDidAppear:(BOOL)animated
{
	// show the annotations
	//[self hideAnnotations:NO];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {

	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	_mapView.delegate = nil;
	[_mapView release];

	[_toolBar release];

	[_geoButton release];
	
	[_shuttleButton release];
	
	[_shuttleAnnotations release];
	
	[_searchResults release];
	_searchResults = nil;
	
	[_categories release];
	
	[_categoryTableView release];

	
	[_selectedCategory release];
	
	[_viewTypeButton release];
	[_searchResultsVC release];
	[_searchBar release];
	
}


- (void)dealloc {
    [super dealloc];
}

-(void) setSearchResults:(NSArray *)searchResults
{
	_searchFilter = nil;
	
	[_mapView removeAnnotations:_searchResults];
	[_mapView removeAnnotations:_filteredSearchResults];
	
	[_searchResults release];
	_searchResults = [searchResults retain];
	
	[_filteredSearchResults release];
	_filteredSearchResults = nil;
	
	if (nil != _searchResultsVC) {
		_searchResultsVC.searchResults = _searchResults;
	}
	
	[_mapView addAnnotations:_searchResults];
	
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
	}
	
	// if we're showing the map, only enable the list button if there are search results. 
	//if (!_displayList) {
	//	_viewTypeButton.enabled = (_searchResults != nil && _searchResults.count > 0);
	//}
	
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
	
	// if we're showing the map, only enable the list button if there are search results. 
	//if (!_displayList) {
	//	_viewTypeButton.enabled = (_searchResults != nil && _searchResults.count > 0);
	//}
	
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
													 message:NSLocalizedString(@"No results found.", nil)
													delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
	alert.tag = kNoSearchResultsTag;
	alert.delegate = self;
	[alert show];
}

-(void) errorConnectingAlert
{
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
													 message:NSLocalizedString(@"Error connecting. Please check your internet connection.", nil)
													delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
	alert.tag = kErrorConnectingTag;
	alert.delegate = self;
	[alert show];
}


#pragma mark UIAlertViewDelegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// if the alert view was "no search results", give focus back to the search bar
	if (alertView.tag = kNoSearchResultsTag) {
		[_searchBar becomeFirstResponder];
	}
}


#pragma mark User actions
-(void) geoLocationTouched:(id)sender
{
	//_mapVC.showsUserLocation = !_mapVC.showsUserLocation;
	_mapView.stayCenteredOnUserLocation = !_mapView.stayCenteredOnUserLocation;
	
	_geoButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
}

-(void) shuttleButtonTouched:(id)sender
{
	_displayShuttles = !_displayShuttles;
	
	_shuttleButton.style = _displayShuttles ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	
	if (_displayShuttles) 
	{
		// if we already have the shuttle information, just display it. If not, file a request. 
		if (nil != [[ShuttleDataManager sharedDataManager] shuttleStops]) {
			[self addAnnotationsForShuttleStops:[[ShuttleDataManager sharedDataManager] shuttleStops]];
		}
		else 
		{
			[[ShuttleDataManager sharedDataManager] requestStops];
		}

	}
	else {
		[_mapView removeAnnotations:_shuttleAnnotations];
		[_shuttleAnnotations release];
		_shuttleAnnotations = nil;
	}

}

-(void) showListView:(BOOL)showList
{

	if (showList) 
	{
		// if we are not already showing the list, do all this 
		if (!_displayList) 
		{
			
			_viewTypeButton.title = @"Map";
			
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
			_toolBar.hidden = YES;
			_searchBar.frame = CGRectMake(_searchBar.frame.origin.x, 
										  _searchBar.frame.origin.y,
										  self.view.frame.size.width,
										  _searchBar.frame.size.height);
			
		}
		
		// we can always allow the user to switch back to the map
		//_viewTypeButton.enabled = YES;
		
	}
	else 
	{
		// if we're not already showing the map
		if (_displayList)
		{
			_viewTypeButton.title = @"List";
			
			// show the map, by hiding the list. 
			[_searchResultsVC.view removeFromSuperview];
			[_searchResultsVC release];
			_searchResultsVC = nil;
			
			// show the toolbar and shring the search bar. 
			_toolBar.hidden = NO;
			_searchBar.frame = CGRectMake(_searchBar.frame.origin.x, 
										  _searchBar.frame.origin.y,
										  kSearchBarWidth,
										  _searchBar.frame.size.height);
		}
	
		// only let the user switch to the list view if there are search results. 
		//_viewTypeButton.enabled = (_searchResults != nil && _searchResults.count > 0);
		
	}
	
	_displayList = showList;
	
}

-(void) viewTypeChanged:(id)sender
{
	[self showListView:!_displayList];
	
	/*
	UISegmentedControl* viewTypeSegmentedControl = (UISegmentedControl*)sender;
	
	if(viewTypeSegmentedControl.selectedSegmentIndex == 1)
	{
		
		CategoriesViewController* categoriesTableView = [[[CategoriesViewController alloc] initWithNibName:@"CategoriesViewController"
																											  bundle:nil] autorelease];
		categoriesTableView.categories = _categories;
		categoriesTableView.navigationItem.hidesBackButton = YES;
		categoriesTableView.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		categoriesTableView.title = @"Campus Map";
		categoriesTableView.searchAvailable = YES;
		categoriesTableView.campusMapVC = self;
		
		[self.navigationController pushViewController:categoriesTableView animated:(_searchResults == nil)];
		
		if (nil != _searchResults) 
		{
			MITMapSearchResultsVC* searchResultsVC = [[[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC"
																													bundle:nil] autorelease];
			
			searchResultsVC.title = @"Campus Map";
			searchResultsVC.searchResults = _searchResults;
			searchResultsVC.navigationItem.hidesBackButton = (_selectedCategory == nil);
			searchResultsVC.searchAvailable = (_selectedCategory == nil);
			searchResultsVC.campusMapVC = self;
			
			searchResultsVC.view;
			searchResultsVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
			
			searchResultsVC.searchBar.text = _lastSearchText;
			
			[self.navigationController pushViewController:searchResultsVC animated:YES];
			
		}
		

	}
	else {
		
		[self.navigationController popToRootViewControllerAnimated:YES];

	}
*/
	

}

-(void) receivedNewSearchResults:(NSArray*)searchResults
{
	// clear the map view's annotations, and add new ones for these search results
	//[_mapView removeAnnotations:_searchResults];
	//[_searchResults release];
	//_searchResults = nil;
	
	NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:searchResults.count];
	
	for (NSDictionary* info in searchResults)
	{
		MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:info] autorelease];
		[searchResultsArr addObject:annotation];
	}
	
	// this will remove old annotations and add the new ones. 
	self.searchResults = searchResultsArr;
	
	/*
	// if we have 2 view controllers, push a new search results controller onto the stack
	if (self.navigationController.viewControllers.count == 2) {
		MITMapSearchResultsVC* searchResultsVC = [[[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC"
																												bundle:nil] autorelease];
		searchResultsVC.view;
		searchResultsVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		searchResultsVC.title = @"Campus Map";
		searchResultsVC.searchResults = self.searchResults;
		searchResultsVC.navigationItem.hidesBackButton = YES;
		
		searchResultsVC.campusMapVC = self;
				
		[self.navigationController pushViewController:searchResultsVC animated:YES];
	}
	
	// if we have 3 view controllers, update the search results in the search results view controller. 
	if (self.navigationController.viewControllers.count == 3) {
		MITMapSearchResultsVC* searchResultsVC = (MITMapSearchResultsVC*)[self.navigationController.viewControllers objectAtIndex:2];
		searchResultsVC.searchResults = self.searchResults;
	}
	 */
	
}

-(void) receivedNewCategories:(NSArray*) categories
{
	NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:categories.count];
	
	for (NSDictionary* info in categories) {
		MITMapCategory* category = [[[MITMapCategory alloc] initWithInfo:info] autorelease];
		[arr addObject:category];
	}
	
	[_categories release];
	_categories = arr;
}


#pragma mark UISearchBarDelegate
#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	
	// ask the campus map view controller to perform the search
	[self search:searchBar.text];
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	[searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (searchText.length == 0 )
	{
		
		// tell the campus view controller to remove its search results. 
		[self search:nil];
		
	}
}

-(void) touchEnded
{
	[_searchBar resignFirstResponder];
}


#pragma mark MITMapViewControllerDelegate
-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
	_geoButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
		/*
	MKCoordinateRegion region =  mapView.region;
	
	// save the region

	NSNumber* centerLat = [NSNumber numberWithDouble:region.center.latitude];
	NSNumber* centerLon = [NSNumber numberWithDouble:region.center.longitude];
	NSNumber* latDelta = [NSNumber numberWithDouble:region.span.latitudeDelta];
	NSNumber* lonDelta = [NSNumber numberWithDouble:region.span.longitudeDelta];

	NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
	
	[standardDefaults setValue:centerLat forKey:@"mapCenterLat"];
	[standardDefaults setValue:centerLon forKey:@"mapCenterLon"];
	[standardDefaults setValue:latDelta  forKey:@"mapLatDelta"];
	[standardDefaults setValue:lonDelta  forKey:@"mapLonDelta"];
	*/
}

- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
	_geoButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
}

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
	{
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation] autorelease];
		UIImage* pin = [UIImage imageNamed:@"map_pin_shuttle_stop_complete.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = YES;
		[annotationView addSubview:imageView];
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	
	return annotationView;
}

// a callout accessory control was tapped. 
- (void)mapView:(MITMapView *)mapView annotationViewcalloutAccessoryTapped:(MITMapAnnotationCalloutView *)view 
{
	
	// determine the type of the annotation. If it is a search result annotation, display the details
	if ([view.annotation isKindOfClass:[MITMapSearchResultAnnotation class]]) 
	{
		
		// push the details page onto the stack for the item selected. 
		MITMapDetailViewController* detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
																							  bundle:nil] autorelease];
		
		detailsVC.annotation = view.annotation;
		detailsVC.title = @"Info";
		detailsVC.campusMapVC = self;
		
		
		if (self.selectedCategory) 
		{
			detailsVC.queryText = detailsVC.annotation.name;
		}
		else if(self.lastSearchText != nil && self.lastSearchText.length > 0)
		{
			detailsVC.queryText = self.lastSearchText;
		}
	
		
		
		[self.navigationController pushViewController:detailsVC animated:YES];		
	}

	else if ([view.annotation isKindOfClass:[ShuttleStopMapAnnotation class]])
	{
		
		// move this logic to the shuttle module
		ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)view.annotation shuttleStop];
		[self.navigationController pushViewController:shuttleStopVC animated:YES];
		
	}
	
	
}

- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch
{
	[_searchBar resignFirstResponder];
}
#pragma mark PostDataDelegate
-(void) postData:(PostData*)postData receivedData:(NSData*) data
{

	NSString* stringResult = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

	if ([postData.api isEqualToString:kAPISearch]) 
	{

		NSArray* searchResults = [stringResult JSONValue];
		
		[_lastSearchText release];
		_lastSearchText = [[postData.userData objectForKey:@"searchText"] retain];
		
		[self receivedNewSearchResults:searchResults];
		
		// if there were no search results, tell the user about it. 
		if(nil == searchResults || searchResults.count <= 0)
			[self noSearchResultsAlert];
	}

	else if ([postData.api isEqualToString:kAPICategories])
	{
		NSArray* searchResults = [stringResult JSONValue];
		[self receivedNewCategories:searchResults];
	}
	
}


// there was an error connecting to the specified URL. 
-(void) postData:(PostData*)postData error:(NSString*)error
{
	if([postData.api isEqualToString:kAPISearch])
	{
		[self errorConnectingAlert];
	}
}
 

#pragma mark UITableViewDataSource

-(void) search:(NSString*)searchText
{
	_selectedCategory = nil;
	
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
		// turn off locate me
		_geoButton.style = UIBarButtonItemStylePlain;
		_mapView.stayCenteredOnUserLocation = NO;
		
		NSString* urlString = [NSString stringWithFormat:[MITMapSearchResultAnnotation urlSearchString], [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
		postData.api = kAPISearch;
		postData.userData = [NSDictionary dictionaryWithObject:searchText forKey:@"searchText"];
		
		postData.useNetworkActivityIndicator = YES;
		[postData postDataInDictionary:nil toURL:[NSURL URLWithString:urlString]];
	}
	

}




@end
