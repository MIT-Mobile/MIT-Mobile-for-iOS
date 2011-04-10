#import "MapSelectionController.h"
#import "BookmarksTableViewController.h"
#import "RecentSearchesViewController.h"
#import "CategoriesTableViewController.h"

@implementation MapSelectionController
@synthesize toolbarButtonItems = _toolbarButtonItems;
@synthesize mapVC = _mapVC;
@synthesize cancelButton = _cancelButton;

-(id) initWithMapSelectionControllerSegment:(MapSelectionControllerSegment) segment campusMap:(CampusMapViewController*)mapVC;
{
	_mapVC = [mapVC retain];
	
	UIViewController* vc = nil;
	
	
	switch (segment) {
		case MapSelectionControllerSegmentBookmarks:
			vc = [[[BookmarksTableViewController alloc] initWithMapSelectionController:self] autorelease];
			break;
		case MapSelectionControllerSegmentRecents:
			vc = [[[RecentSearchesViewController alloc] initWithMapSelectionController:self] autorelease];			
			break;
		
		case MapSelectionControllerSegmentBrowse:
			vc = [[[CategoriesTableViewController alloc] initWithMapSelectionController:self] autorelease];
			[(CategoriesTableViewController*)vc setTopLevel:YES];
			break;
			
		default:
			
			break;
	}
	
	if(vc != nil)
	{
		self = [super initWithRootViewController:vc];
	}
	else {
		self = [super init];
	}
	
	UISegmentedControl* seg = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Bookmarks", @"Recents", @"Browse", nil]] autorelease];
	seg.selectedSegmentIndex = segment;
	seg.segmentedControlStyle = UISegmentedControlStyleBar;
	seg.tintColor = [UIColor darkGrayColor];
	
	[seg addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
	
    // TODO: Find a way to make this center itself. Hardcoding sizes is awful.
	UIBarButtonItem* item = [[[UIBarButtonItem alloc] initWithCustomView:seg] autorelease];
    item.width = 308.0;
	
	_toolbarButtonItems = [[NSArray arrayWithObject:item] retain];
	
	[self setToolbarHidden:NO];
	[self.toolbar setBarStyle:UIBarStyleBlack];
	
	
	_cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
																	  style:UIBarButtonItemStyleBordered 
																	 target:self 
																	 action:@selector(cancelButtonTapped)];

	return self;
	
}

-(void) dealloc
{
	[_toolbarButtonItems release];
	[_mapVC release];
	[_cancelButton release];
	[super dealloc];
}

#pragma mark User Actions
-(void) cancelButtonTapped
{
	[self dismissModalViewControllerAnimated:YES];
}


-(void) segmentChanged:(id)sender
{
	UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
	
	UIViewController* vc = nil;
	
	switch (segmentedControl.selectedSegmentIndex) {
		case MapSelectionControllerSegmentBookmarks:
			vc = [[[BookmarksTableViewController alloc] initWithMapSelectionController:self] autorelease];
			break;
			
		case MapSelectionControllerSegmentRecents:
			vc = [[[RecentSearchesViewController alloc] initWithMapSelectionController:self] autorelease];
			break;
		
		case MapSelectionControllerSegmentBrowse:
			vc = [[[CategoriesTableViewController alloc] initWithMapSelectionController:self] autorelease];
			[(CategoriesTableViewController*)vc setTopLevel:YES];
			break;
			
		default:
			break;
	}
	
	if(nil != vc)
		[self setViewControllers:[NSArray arrayWithObject:vc]];
}

@end
