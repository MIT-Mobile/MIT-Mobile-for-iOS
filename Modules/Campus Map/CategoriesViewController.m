
#import "CategoriesViewController.h"
#import "MITMapCategory.h"
#import "MITMapSearchResultsVC.h"
#import "CampusMapViewController.h"
#import "MITMapSearchResultAnnotation.h"

@implementation CategoriesViewController
@synthesize categories = _categories;
@synthesize campusMapVC = _campusMapVC;

- (void)dealloc {
    [super dealloc];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	self.categories = nil;

	[super viewDidUnload];
}

-(void) viewDidAppear:(BOOL)animated
{
	self.campusMapVC.selectedCategory = nil;
	self.campusMapVC.searchResults = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.categories.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	cell.textLabel.text = [[self.categories objectAtIndex:indexPath.row] categoryName];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}




- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Browse by:";
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MITMapCategory* category = [_categories objectAtIndex:indexPath.row]; 
	NSArray* categoryItems = [category categoryItems];
	
	MITMapSearchResultsVC* searchResultsVC = [[[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC"
																											bundle:nil] autorelease];
	searchResultsVC.searchResults = categoryItems;
	searchResultsVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
	searchResultsVC.campusMapVC = self.campusMapVC;
	searchResultsVC.isCategory = YES;
	[self.campusMapVC setSearchResults:categoryItems withFilter:@selector(bldgnum)];
	self.campusMapVC.selectedCategory = category;
	
	
	
	[self.navigationController pushViewController:searchResultsVC animated:YES];
	
	
}






@end

