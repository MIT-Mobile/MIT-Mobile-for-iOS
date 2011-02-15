
#import "MITMapDetailViewController.h"
#import "TabViewControl.h"
#import "MITMapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "NSString+SBJSON.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "MapBookmarkManager.h"

@interface MITMapDetailViewController(Private)

// load the content of the current annotation into the view.
-(void) loadAnnotationContent;

// determine the best name string for this result
//-(NSString*) nameString;

@end


@implementation MITMapDetailViewController
@synthesize annotation = _annotation;
@synthesize annotationDetails = _annotationDetails;
@synthesize campusMapVC = _campusMapVC;
@synthesize queryText = _queryText;
@synthesize imageConnectionWrapper;
@synthesize startingTab = _startingTab;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		networkActivity = NO;
	}
	return self;
}

- (void)dealloc 
{	
	self.annotation = nil;
	self.annotationDetails = nil;
	if (networkActivity) {
		//[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
		[self.imageConnectionWrapper cancel];
	}
	self.imageConnectionWrapper.delegate = nil;
	self.imageConnectionWrapper = nil;
	
    [super dealloc];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	_tabViews = [[NSMutableArray alloc] initWithCapacity:2];
	
	// check if this item is already bookmarked
	MapBookmarkManager* bookmarkManager = [MapBookmarkManager defaultManager];
	if ([bookmarkManager isBookmarked:self.annotation.uniqueID]) {
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:UIControlStateHighlighted];
	}
	
	/*
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSArray* bookmarks = [NSArray arrayWithContentsOfFile:[docsFolder stringByAppendingPathComponent:@"bookmarks.plist"]];
	for (NSDictionary* bookmark in bookmarks) {
		if ([[bookmark objectForKey:@"bldgnum"] isEqualToString:self.annotation.bldgnum]) {
			[_bookmarkButton setImage:[UIImage imageNamed:@"bookmark_on.png"] forState:UIControlStateNormal];
			[_bookmarkButton setImage:[UIImage imageNamed:@"bookmark_on_pressed.png"] forState:UIControlStateHighlighted];
			break;
		}
	}
	*/
	
	_mapView.delegate = self;

	_mapView.scrollEnabled = NO;
	_mapView.userInteractionEnabled = NO;
	_mapView.layer.cornerRadius = 6.0;
	_mapViewContainer.layer.cornerRadius = 8.0;
	
	// buffer the annotation by 5px so it fits in the map thumbnail window.
	//CGPoint screenPoint = [_mapView unscaledScreenPointForCoordinate:self.annotation.coordinate];
	//screenPoint.y -= 5;
	//CLLocationCoordinate2D coordinate = [_mapView coordinateForScreenPoint:screenPoint];
	//_mapView.centerCoordinate = coordinate;
	[_mapView addAnnotation:self.annotation];
	_mapView.centerCoordinate = self.annotation.coordinate;
	[_mapView setRegion:MKCoordinateRegionMake(self.annotation.coordinate, MKCoordinateSpanMake(0.003, 0.003))];
	
	
	
	[_mapView deselectAnnotation:self.annotation animated:NO];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Google Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(externalMapButtonPressed:)] autorelease];
	
	// never resize the tab view container below this height. 
	_tabViewContainerMinHeight = _tabViewContainer.frame.size.height;
	
	// if there was a query, populate the query label, otherwise hide it and move everything else up
	//if (_campusMapVC.lastSearchText != nil && _campusMapVC.lastSearchText.length > 0) {
	//	_queryLabel.text = [NSString stringWithFormat:@"\"%@\" was found in:", _campusMapVC.lastSearchText];
	//}
	if(self.queryText != nil && self.queryText.length > 0)
	{
		_queryLabel.text = [NSString stringWithFormat:@"\"%@\" was found in:", self.queryText];
	}
	else {
		_queryLabel.hidden = YES;
		_nameLabel.frame = CGRectMake(_nameLabel.frame.origin.x, _nameLabel.frame.origin.y - _queryLabel.frame.size.height,
									  _nameLabel.frame.size.width, _nameLabel.frame.size.height);
		
		_locationLabel.frame = CGRectMake(_locationLabel.frame.origin.x, _locationLabel.frame.origin.y - _queryLabel.frame.size.height,
										  _locationLabel.frame.size.width, _locationLabel.frame.size.height);
	}
	
	// if the annotation was not fully loaded, go get the rest of the data. 
	if (!self.annotation.dataPopulated) 
	{
		// show the loading result view and hide the rest
		_nameLabel.hidden = YES;
		_locationLabel.hidden = YES;
		_tabViewControl.hidden = YES;
		_tabViewContainer.hidden = YES;
		
		[_scrollView addSubview:_loadingResultView];
		
		[MITMapSearchResultAnnotation executeServerSearchWithQuery:self.annotation.bldgnum jsonDelegate:self object:nil];		
	}
	else {
		self.annotationDetails = self.annotation;
		[self loadAnnotationContent];
	}

	if (_startingTab) {
		_tabViewControl.selectedTab = _startingTab;
	}
}

-(void) externalMapButtonPressed:(id) sender
{
	NSString *search = nil;
	
	if (nil == self.annotation.street) {
		NSString* desc = self.annotation.name;
		
		if (nil != self.annotation.bldgnum) {
			desc = [desc stringByAppendingFormat:@" - Building %@", self.annotation.bldgnum];
		}

		search = [NSString stringWithFormat:@"%lf,%lf(%@)", self.annotation.coordinate.latitude, self.annotation.coordinate.longitude, desc];

	} else {
		
		search = self.annotation.street;
	
		// clean up the string
		NSRange parenRange = [search rangeOfString:@"("];
		if (parenRange.location != NSNotFound) {
			search = [search substringToIndex:parenRange.location];
		}
		NSRange accessViaRange = [search rangeOfString:@"Access Via"];
		if (accessViaRange.location != NSNotFound) {
			search = [search substringFromIndex:accessViaRange.length];
		}
		
		if (self.annotation.city == nil) {
			search = [search stringByAppendingString:@", Cambridge, MA"];
		}
		else {
			search = [search stringByAppendingFormat:@", %@", self.annotation.city];
		}
	}
	
	NSString *url = [NSString stringWithFormat: @"http://maps.google.com/maps?q=%@", [search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
/*
-(NSString*) nameString
{
	NSString* nameString = nil;
	if (self.annotationDetails.bldgnum != nil) {
		nameString = [NSString stringWithFormat:@"Building %@ (%@)", self.annotationDetails.bldgnum, self.annotationDetails.name];
	}
	else {
		nameString = self.annotation.name;
	}
	
	return nameString;
}
*/

-(void) loadAnnotationContent
{
	[_loadingResultView removeFromSuperview];
	_nameLabel.hidden = NO;
	_locationLabel.hidden = NO;
	
	if (self.annotationDetails.contents.count > 0) {
		
		CGFloat padding = 10.0;
		CGFloat currentHeight = padding;
		CGFloat bulletWidth = 24.0;
		UIFont *whatsHereFont = [UIFont systemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
		for (NSString* content in self.annotationDetails.contents) {
			
			CGSize textSize = [content sizeWithFont:whatsHereFont 
								  constrainedToSize:CGSizeMake(_whatsHereView.frame.size.width - bulletWidth - 2 * padding, 400.0) 
									  lineBreakMode:UILineBreakModeWordWrap];

			UILabel *bullet = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentHeight, bulletWidth - padding, 20.0)];
			bullet.text = @"•";
			[_whatsHereView addSubview:bullet];
			[bullet release];
			
			UILabel *listItem = [[UILabel alloc] initWithFrame:CGRectMake(bulletWidth, currentHeight, textSize.width, textSize.height)];
			listItem.text = content;
			listItem.lineBreakMode = UILineBreakModeWordWrap;
			listItem.numberOfLines = 0;
			[_whatsHereView addSubview:listItem];
			[listItem release];
			
			currentHeight += textSize.height;
		}
		// resize the what's here view to contain the full label
		_whatsHereView.frame = CGRectMake(_whatsHereView.frame.origin.x,
										  _whatsHereView.frame.origin.y,
										  _whatsHereView.frame.size.width,
										  currentHeight + padding);
		
		
		// resize the content container if the what's here view is bigger than it
		if (_whatsHereView.frame.size.height > _tabViewContainer.frame.size.height) {
			_tabViewContainer.frame = CGRectMake(_tabViewContainer.frame.origin.x,
												 _tabViewContainer.frame.origin.y,
												 _tabViewContainer.frame.size.width,
												 (_whatsHereView.frame.size.height > _tabViewContainerMinHeight ) ? _whatsHereView.frame.size.height : _tabViewContainerMinHeight);
			
			CGSize contentSize = CGSizeMake(_scrollView.frame.size.width, _tabViewContainer.frame.size.height + _tabViewContainer.frame.origin.y);
			[_scrollView setContentSize:contentSize];
		}
	} else {
		UILabel* noWhatsHereLabel = [[[UILabel alloc] initWithFrame:CGRectMake(13, 6, _whatsHereView.frame.size.width, 20)] autorelease];
		noWhatsHereLabel.text = NSLocalizedString(@"No Information Available", nil);
		[_whatsHereView addSubview:noWhatsHereLabel];
		
	}
	
	[_tabViewControl addTab:@"What's Here"];
	[_tabViews addObject:_whatsHereView];
	
	if (self.annotationDetails.bldgimg) 
	{
		// go get the image.
		self.imageConnectionWrapper = [[ConnectionWrapper new] autorelease];
		self.imageConnectionWrapper.delegate = self;
		[imageConnectionWrapper requestDataFromURL:[NSURL URLWithString:self.annotationDetails.bldgimg] allowCachedResponse:YES];
		
		NSString* decriptionText = self.annotationDetails.viewAngle ? [NSString stringWithFormat:@"View from: %@", self.annotationDetails.viewAngle] : nil ;
		_buildingImageDescriptionLabel.text = decriptionText;
		
		[_tabViewControl addTab:@"Photo"];	
		[_tabViews addObject:_buildingView];
	}
	
	// if no tabs have been added, remove the tab view control and its container view. 
	if (_tabViewControl.tabs.count <= 0) {
		_tabViewControl.hidden = YES;
		_tabViewContainer.hidden = YES;
	}
	else
	{
		_tabViewControl.hidden = NO;
		_tabViewContainer.hidden = NO;
	}
	
	[_tabViewControl setNeedsDisplay];
	
	
	[_tabViewControl setDelegate:self];
	
	
	// set the labels
	//NSString* nameString = [self nameString];
	_nameLabel.text = self.annotation.title;
	_nameLabel.numberOfLines = 0;
	CGSize stringSize = [self.annotation.title sizeWithFont:_nameLabel.font 
							   constrainedToSize:CGSizeMake(_nameLabel.frame.size.width, 200.0)
								   lineBreakMode:UILineBreakModeWordWrap];
	_nameLabel.frame = CGRectMake(_nameLabel.frame.origin.x, 
								  _nameLabel.frame.origin.y,
								  _nameLabel.frame.size.width, stringSize.height);
	
	_locationLabel.text = self.annotationDetails.street;
	CGSize addressSize = [self.annotationDetails.street sizeWithFont:_locationLabel.font 
										  constrainedToSize:CGSizeMake(_locationLabel.frame.size.width, 200.0)
											  lineBreakMode:UILineBreakModeWordWrap];
    
    CGRect frame = _locationLabel.frame;
    frame.origin.y = _nameLabel.frame.size.height + _nameLabel.frame.origin.y + 1;
    frame.size.height = addressSize.height;
    _locationLabel.frame = frame;
    
    CGFloat originY = _locationLabel.frame.origin.y + _locationLabel.frame.size.height + 5;
	
	if (originY > _tabViewControl.frame.origin.y) {
        frame = _tabViewControl.frame;
        frame.origin.y = originY;
        _tabViewControl.frame = frame;
        
        frame = _tabViewContainer.frame;
        frame.origin.y = _tabViewControl.frame.origin.y + _tabViewControl.frame.size.height;
        frame.size.height = (_tabViewContainer.frame.size.height > _tabViewContainerMinHeight) ? _tabViewContainer.frame.size.height : _tabViewContainerMinHeight;
        _tabViewControl.frame = frame;
	}
	
	// force the correct tab to load
	if(_tabViews.count > 0)
	{

		if (self.annotationDetails.contents.count == 0 && _tabViews.count > 1) {
			_tabViewControl.selectedTab = 1;
			[self tabControl:_tabViewControl changedToIndex:1 tabText:nil];
		}
		else {
			_tabViewControl.selectedTab = 0;
			[self tabControl:_tabViewControl changedToIndex:0 tabText:nil];
		}


	}
	
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	
	[_tabViewControl release];
	
	[_nameLabel release];
	
	[_locationLabel release];
	
	[_tabViewContainer release];

	[_buildingView release];
	
	[_buildingImageView release];
	
	[_buildingImageDescriptionLabel release];
	
	[_whatsHereView release];
	
	[_tabViews release];
	
	[_loadingImageView release];
	
	[_loadingResultView release];
	
}

#pragma mark User Actions
-(IBAction) mapThumbnailPressed:(id)sender
{
	
	// on the map, select the current annotation
	[_campusMapVC.mapView selectAnnotation:self.annotation animated:NO withRecenter:YES];
	
	// make sure the map is showing. 
	[_campusMapVC showListView:NO];
	
	// pop back to the map view. 
	[self.navigationController popToViewController:self.campusMapVC animated:YES];
	
}

-(IBAction) bookmarkButtonTapped
{
	MapBookmarkManager* bookmarkManager = [MapBookmarkManager defaultManager];
	if ([bookmarkManager isBookmarked:self.annotation.uniqueID])
	{
		// remove the bookmark and set the images
		[bookmarkManager removeBookmark:self.annotation.uniqueID];
		
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:UIControlStateHighlighted];
	}
	else 
	{
		NSString* subTitle = nil;
		if (self.annotation.bldgnum != nil) {
			subTitle = [NSString stringWithFormat:@"Building %@", self.annotation.bldgnum];
		}
		[bookmarkManager addBookmark:self.annotation.uniqueID title:self.annotation.name subtitle:subTitle data:self.annotation.info];
		
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:UIControlStateHighlighted];
	}
	
}

#pragma mark TabViewControlDelegate
-(void) tabControl:(TabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText
{
	// change the content based on the tab that was selected
	for(UIView* subview in [_tabViewContainer subviews])
	{
		[subview removeFromSuperview];
	}

	// set the size of the scroll view based on the size of the view being added and its parent's offset
	UIView* viewToAdd = [_tabViews objectAtIndex:tabIndex];
	_scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width,
										 _tabViewContainer.frame.origin.y + viewToAdd.frame.size.height);
	
	[_tabViewContainer addSubview:viewToAdd];
	
	if (_campusMapVC.displayingList)
		[_campusMapVC.url setPath:[NSString stringWithFormat:@"list/detail/%@/%d", _annotation.uniqueID, tabIndex] query:_campusMapVC.lastSearchText];
	else 
		[_campusMapVC.url setPath:[NSString stringWithFormat:@"detail/%@/%d", _annotation.uniqueID, tabIndex] query:_campusMapVC.lastSearchText];
	[_campusMapVC.url setAsModulePath];
	[_campusMapVC setURLPathUserLocation];
}


#pragma mark JSONLoadedDelegate
// data was received from the MITMobileWeb request. 
-(void) request:request jsonLoaded:(id)results {
	if ([(NSArray *)results count] > 0) {
		MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:[results objectAtIndex:0]] autorelease];
		self.annotationDetails = annotation;
		
		// load the new contents. 
		[self loadAnnotationContent];
	}
}

- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return NO;
}

#pragma mark ConnectionWrapper
-(void) connectionDidReceiveResponse: (ConnectionWrapper *)connectionWrapper {
	//[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
	networkActivity = YES;
}

-(void) connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	//[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	networkActivity = NO;
	
	_loadingImageView.hidden = YES;
	
	// create an image from the data and set it on the view
	UIImage* image = [UIImage imageWithData:data];
	_buildingImageView.image = image;
	self.imageConnectionWrapper = nil;
}
	
-(void) connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	//[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	networkActivity = NO;
	
	self.imageConnectionWrapper = nil;
	_loadingImageView.hidden = YES;
}

#pragma mark MITMapViewDelegate
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[MITMapSearchResultAnnotation class]]) 
	{
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"] autorelease];
		UIImage* pin = [UIImage imageNamed:@"map/map_pin_complete.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		annotationView.frame = imageView.frame;
		annotationView.showsCustomCallout = NO;
		[annotationView addSubview:imageView];
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.centeredVertically = YES;
		//annotationView.alreadyOnMap = YES;
	}
	
	return annotationView;
}

@end
