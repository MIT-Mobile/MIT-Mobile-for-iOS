#import "RecentSearchesViewController.h"
#import "CoreDataManager.h"
#import "MITConstants.h"
#import "MITUIConstants.h"
#import "MapSelectionController.h"
#import "MapSearch.h"
#import "CampusMapViewController.h"

@interface RecentSearchesViewController ()
@property (nonatomic,copy) NSArray *searches;
@end

@implementation RecentSearchesViewController
#pragma mark - Initialization
- (id)initWithMapSelectionController:(MapSelectionController*)mapSelectionController
{
	self = [super init];

	if (self) {
		self.mapSelectionController = mapSelectionController;
		[self setToolbarItems:self.mapSelectionController.toolbarButtonItems];
	}
	
	return self;
}


#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	self.searches = [CoreDataManager fetchDataForAttribute:CampusMapSearchEntityName sortDescriptor:sortDescriptor];
	self.title = @"Recent Searches";
	
	self.navigationItem.rightBarButtonItem = self.mapSelectionController.cancelButton;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.tableView reloadData];
}

- (void)viewDidUnload {
	self.searches = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.searches count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    }

    MapSearch* search = self.searches[indexPath.row];
    cell.textLabel.text = search.searchTerm;
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// determine the search term they selected. 
	MapSearch* search = self.searches[indexPath.row];
	
	self.mapSelectionController.mapVC.searchBar.text = search.searchTerm;
	[self.mapSelectionController.mapVC search:search.searchTerm];
	
	[self dismissModalViewControllerAnimated:YES];
}

@end

