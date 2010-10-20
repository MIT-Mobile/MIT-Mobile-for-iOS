
#import "StellarSearch.h"
#import "StellarClass.h"
#import "StellarDetailViewController.h"
#import "StellarMainTableController.h"
#import "StellarClassTableCell.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"



@implementation StellarSearch

@synthesize lastResults;
@synthesize activeMode;
@synthesize searchBar;

- (void) cancelSearch {
	activeMode = NO;
	[viewController.searchController setActive:NO animated:YES];
	
	[viewController hideSearchResultsTable];
	[viewController hideTranslucentOverlay];
	[viewController hideLoadingView];
	[viewController reloadMyStellarUI];
}

- (BOOL) isSearchResultsVisible {
	return hasSearchCompleted && activeMode;
}
	
- (id) initWithSearchBar: theSearchBar viewController: (StellarMainTableController *)controller{
	if(self = [super init]) {
		activeMode = NO;
		searchBar = [theSearchBar retain];
        searchBar.delegate = self;
		viewController = controller;
		self.lastResults = [NSArray array];
		hasSearchCompleted = NO;
	}
	return self;
}

- (void) dealloc {
    [searchBar release];
	[lastResults release];
	[super dealloc];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [lastResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"StellarSearch"];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarSearch"] autorelease];
	}

	StellarClass *stellarClass = [self.lastResults objectAtIndex:indexPath.row];
	[StellarClassTableCell configureCell:cell withStellarClass:stellarClass];
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	if([lastResults count]) {
		if([lastResults count]==1) {
			return @"1 match found.";
		} else {
			return [NSString stringWithFormat:@"%i matches found.", [lastResults count]];
		}
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	if([lastResults count]) {
		if([lastResults count]==1) {
			headerTitle = @"1 match found.";
		} else {
			headerTitle = [NSString stringWithFormat:@"%i matches found.", [lastResults count]];
		}
		return [UITableView ungroupedSectionHeaderWithTitle:headerTitle];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark UITableViewDelegate methods
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[StellarDetailViewController 
		launchClass:(StellarClass *)[self.lastResults objectAtIndex:indexPath.row]
		viewController:viewController];
}

#pragma mark UISearchDisplayController methods
- (BOOL) searchDisplayController: (UISearchDisplayController *)controller shouldReloadTableForSearchString: (NSString *)searchString {
	return NO;
}

- (BOOL) searchDisplayController: (UISearchDisplayController *)controller shouldReloadTableForSearchScope: (NSInteger)searchOption {
	return NO;
}

- (void) searchDisplayController: (UISearchDisplayController *)controller didShowSearchResultsTableView: (UITableView *)tableView {
	if(!hasSearchCompleted) {
		[viewController hideSearchResultsTable];
	}
}

#pragma mark ClassesSearchDelegate methods
- (void) searchComplete: (NSArray *)classes searchTerms:searchTerms {
	if([searchBar.text isEqualToString:searchTerms]) {
		self.lastResults = classes;
		hasSearchCompleted = YES;
		[viewController.translucentOverlay removeFromSuperview];
		
		[viewController.searchController.searchResultsTableView applyStandardCellHeight];
		viewController.searchController.searchResultsTableView.allowsSelection = YES;
		[viewController.searchController.searchResultsTableView reloadData];
		[viewController hideLoadingView];
		[viewController hideTranslucentOverlay];
		[viewController showSearchResultsTable];
		
		// if exactly one result found forward user to that result
		if([classes count] == 1) {
			[StellarDetailViewController 
				launchClass:(StellarClass *)[classes lastObject]
				viewController: viewController];
		}
	}
}

- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms {
	if([searchBar.text isEqualToString:searchTerms]) {
		[viewController hideLoadingView];
		UIAlertView *alert = [[UIAlertView alloc]
			initWithTitle:@"Connection Failed" 
			message:@"Could not connect to Stellar to execute search, please try again later."
			delegate:nil
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];
		
		[viewController.searchController.searchResultsTableView reloadData];
		[alert show];
		[alert release];
	}
}

#pragma mark UISearchBarDelegate methods
- (void) searchBarSearchButtonClicked: (UISearchBar *)theSearchBar {
	[viewController showLoadingView];
	[StellarModel executeStellarSearch:theSearchBar.text delegate:self];
}

- (void) searchDisplayControllerWillBeginSearch: (UISearchDisplayController *)controller {
	activeMode = YES;
}

- (void) searchDisplayControllerDidEndSearch: (UISearchDisplayController *)controller {
	[self cancelSearch];
}

- (void) searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchText {
	[viewController hideSearchResultsTable];
	
	[viewController hideLoadingView]; // just in case the loading view is showing
	
	// this is to simulate the native searchDisplayControllers overlay for many characters
	
	// we use a delay to work around the issue where apple draws the headers of
	// the tableView behind the Overlay after drawing the overlay
	if(viewController.myStellarUIisUpToDate) {
		// use the delay trick as little as possible (it causes a flicker)
		[viewController showTranslucentOverlay];
	} else {
		[viewController performSelector:@selector(showTranslucentOverlay) withObject:nil afterDelay:0.001];
	}
	
	[viewController reloadMyStellarUI];
	
	hasSearchCompleted = NO;
}

@end
