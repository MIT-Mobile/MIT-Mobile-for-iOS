#import "CategoriesTableViewController.h"
#import "MapSelectionController.h"
#import "MITMapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"

#define kAPICategoryTitles	@"CategoryTitles"
#define kAPICategory		@"Category"

@implementation CategoriesTableViewController
@synthesize mapSelectionController = _mapSelectionController;
@synthesize itemsInTable = _itemsInTable;
@synthesize headerText = _headerText;
@synthesize topLevel = _topLevel;
@synthesize leafLevel = _leafLevel;

#pragma mark -
#pragma mark Initialization


-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		_mapSelectionController = [mapSelectionController retain];
	}
	
	return self;
}

-(id) initWithMapSelectionController:(MapSelectionController *)mapSelectionController andStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	if (self) {
		_mapSelectionController = [mapSelectionController retain];
	}
	
	return self;
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    self.title = @"Browse";
	self.navigationItem.leftBarButtonItem.title = @"Back";
	self.navigationItem.rightBarButtonItem = self.mapSelectionController.cancelButton;
    
    CGRect loadingFrame = [MITAppDelegate() rootNavigationController].view.bounds;
	
	if (_topLevel) {
		_headerText = @"Browse map by:";
		MITMobileWebAPI *apiRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
		apiRequest.userData = @"CategoryTitles";
		[apiRequest requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"categorytitles", @"command", nil]
					pathExtension:@"map/"];
		
		if (!_loadingView) 
		{
			self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			_loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame]
							retain];
			[self.view addSubview:_loadingView];
		}
	}
	
	if(_leafLevel)
	{
		if (!_loadingView) 
		{
			self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			_loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame]
							retain];
			[self.view addSubview:_loadingView];
		}
	}
	
	[self setToolbarItems:self.mapSelectionController.toolbarButtonItems];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.itemsInTable.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    }
    
	if ([[self.itemsInTable objectAtIndex:indexPath.row] objectForKey:@"categoryName"]) {
		cell.textLabel.text = [[self.itemsInTable objectAtIndex:indexPath.row] objectForKey:@"categoryName"];
	} 
	else
	{
		NSString* displayName = [[self.itemsInTable objectAtIndex:indexPath.row] objectForKey:@"displayName"];
		if ([displayName isKindOfClass:[NSString class]]) {
			cell.textLabel.text = displayName;
		}
		else
			cell.textLabel.text = nil;

	}


	if (!_leafLevel) 
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.backgroundColor = [UIColor whiteColor];
	}
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary* thisItem = [self.itemsInTable objectAtIndex:indexPath.row];
	
	if (_leafLevel) {
		
		// make sure the map is showing. 
		[self.mapSelectionController.mapVC showListView:NO];
		
		// clear the search bar
		self.mapSelectionController.mapVC.searchBar.text = @"";
		self.mapSelectionController.mapVC.lastSearchText = nil;
		
		NSMutableArray* searchResultsArray = [NSMutableArray array];

		MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:thisItem] autorelease];
		[searchResultsArray addObject:annotation];
		
		// this will remove any old annotations and add the new ones. 
		[self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
		
		// on the map, select the current annotation
		//[[self.mapSelectionController.mapVC mapView] selectAnnotation:annotation animated:NO withRecenter:YES];
		
		[self dismissModalViewControllerAnimated:YES];
	} else {
	
		CategoriesTableViewController* newCategoriesTVC = nil;
		
		if ([thisItem objectForKey:@"subcategories"]) 
		{
			newCategoriesTVC = [[[CategoriesTableViewController alloc] initWithMapSelectionController:self.mapSelectionController] autorelease];
			newCategoriesTVC.itemsInTable = [thisItem objectForKey:@"subcategories"];
			newCategoriesTVC.headerText = [NSString stringWithFormat:@"Buildings by %@:", [[thisItem objectForKey:@"categoryName"] isEqualToString:@"Building name"] ? @"name" : @"number"];
		} else 
		{
			newCategoriesTVC = [[[CategoriesTableViewController alloc] initWithMapSelectionController:self.mapSelectionController andStyle:UITableViewStylePlain] autorelease];
			[newCategoriesTVC executeServerCategoryRequestWithQuery:[thisItem objectForKey:@"categoryId"]];
			newCategoriesTVC.leafLevel = YES;
			newCategoriesTVC.headerText = [NSString stringWithFormat:@"%@:", [thisItem objectForKey:@"categoryName"]];
		}
		
		newCategoriesTVC.topLevel = NO;
		
		[self.navigationController pushViewController:newCategoriesTVC animated:YES];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView* headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)] autorelease];
//	headerView.backgroundColor = [UIColor yellowColor];
//	headerView.alpha = 0.5;
	if (section == 0) {
		UILabel* headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(16, 10, 226, 40)] autorelease];
		headerLabel.text = self.headerText;
		headerLabel.font = [UIFont boldSystemFontOfSize:16];
		headerLabel.textColor = [UIColor darkGrayColor];
		headerLabel.numberOfLines = 0;
		headerLabel.backgroundColor = [UIColor clearColor];
		//			[headerLabel sizeToFit];
		[headerView addSubview:headerLabel];
		if (_leafLevel) {
			headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
			headerLabel.frame = CGRectMake(headerLabel.frame.origin.x, headerLabel.frame.origin.y, 200, headerLabel.frame.size.height);
			UIButton* viewAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
			UIImage* viewAllImage = [UIImage imageNamed:@"map/map_viewall.png"];
			viewAllButton.frame = CGRectMake(320-viewAllImage.size.width-10, 10, viewAllImage.size.width, viewAllImage.size.height);
			[viewAllButton setImage:viewAllImage forState:UIControlStateNormal];
			[viewAllButton setImage:[UIImage imageNamed:@"map/map_viewall_pressed.png"] forState:UIControlStateHighlighted];
			[viewAllButton addTarget:self action:@selector(mapAllButtonTapped) forControlEvents:UIControlEventTouchUpInside];
			[headerView addSubview:viewAllButton];
		}
	}
	return headerView;
}


#pragma mark MapAll
-(void) mapAllButtonTapped
{
	// make sure the map is showing. 
	[self.mapSelectionController.mapVC showListView:NO];
	
	// clear the search bar
	self.mapSelectionController.mapVC.searchBar.text = @"";
	self.mapSelectionController.mapVC.lastSearchText = nil;
	
	NSMutableArray* searchResultsArray = [NSMutableArray array];
	
	for (NSDictionary* thisItem in self.itemsInTable) {
		MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:thisItem] autorelease];
		[searchResultsArray addObject:annotation];
	}
	
	// this will remove any old annotations and add the new ones. 
	[self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
		
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark JSONLoadedDelegate
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{
	NSArray *categoryResults = JSONObject;
	
	self.itemsInTable = [NSMutableArray arrayWithArray:categoryResults];
	
	if (_loadingView) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		[_loadingView removeFromSuperview];
		[_loadingView release];
		_loadingView = nil;
		
		if(_leafLevel)
			self.tableView.backgroundColor = [UIColor whiteColor];
		
	}
	
	[self.tableView reloadData];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	if (_loadingView) {
		//self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		[_loadingView removeFromSuperview];
		[_loadingView release];
		_loadingView = nil;
	}	
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Map";
}

-(void) executeServerCategoryRequestWithQuery:(NSString *)query 
{
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
	apiRequest.userData = @"Category";
	[apiRequest requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"category", @"command", query, @"id", nil]
				pathExtension:@"map/"];
}


- (void)dealloc {
	self.itemsInTable = nil;
	[_headerText release];
    [super dealloc];
}


@end

