#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PartialHighlightTableViewCell.h"
#import "MIT_MobileAppDelegate.h"
#import "ConnectionDetector.h"
// common UI elements
#import "MITLoadingActivityView.h"
#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"
// external modules
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

// this function puts longer strings first
NSInteger strLenSort(NSString *str1, NSString *str2, void *context)
{
    if ([str1 length] > [str2 length])
        return NSOrderedAscending;
    else if ([str1 length] < [str2 length])
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@implementation PeopleSearchViewController

@synthesize searchTerms, searchTokens, searchResults, recents, searchController;
@synthesize loadingView, searchBackground;
@synthesize searchBar = theSearchBar;

#pragma mark view

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self.tableView applyStandardColors];
	
	// set up table header
	theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 44.0f)];
	theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	
	theSearchBar.delegate = self;
	theSearchBar.placeholder = @"Search";
	if ([self.searchTerms length] > 0)
		theSearchBar.text = self.searchTerms;
	self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:theSearchBar
															  contentsController:self];
	self.searchController.delegate = self;
	self.searchController.searchResultsDelegate = self;
	self.searchController.searchResultsDataSource = self;
	
	static NSString *searchHints = @"Sample searches:\nName: 'william barton rogers', 'rogers'\nEmail: 'wbrogers', 'wbrogers@mit.edu'\nPhone: '6172531000', '31000'";

	UIFont *hintsFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	CGSize labelSize = [searchHints sizeWithFont:hintsFont
									constrainedToSize:self.tableView.frame.size
										lineBreakMode:UILineBreakModeWordWrap];
	
	UILabel *hintsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, labelSize.width, labelSize.height + 5.0)];
	hintsLabel.numberOfLines = 0;
	hintsLabel.backgroundColor = [UIColor clearColor];
	hintsLabel.lineBreakMode = UILineBreakModeWordWrap;
	hintsLabel.font = hintsFont;
	hintsLabel.text = searchHints;	
	UIView *hintsContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, labelSize.width, labelSize.height + 10.0)];
	[hintsContainer addSubview:hintsLabel];
	[hintsLabel release];

	self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 
																			   self.tableView.frame.size.width, 
																			   theSearchBar.frame.size.height + hintsContainer.frame.size.height)] autorelease];
	[self.tableView.tableHeaderView addSubview:theSearchBar];
	[self.tableView.tableHeaderView addSubview:hintsContainer];
	[hintsContainer release];

	// set up screen for when there are no results
	self.recents = [[PeopleRecentsData sharedData] recents];
	recentlyViewedHeader = nil;
	
	// set up table footer
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(10.0, 0.0, self.tableView.frame.size.width - 20.0, 44.0)];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
	[button setTitle:@"Clear Recents" forState:UIControlStateNormal];
	
	// based on code from stackoverflow.com/questions/1427818/iphone-sdk-creating-a-big-red-uibutton
	[button setBackgroundImage:[[UIImage imageNamed:@"redbutton2.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[[UIImage imageNamed:@"redbutton2highlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateHighlighted];
	
	[button addTarget:self action:@selector(showActionSheet) forControlEvents:UIControlEventTouchUpInside];	
	
	UIView *buttonContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 44.0)] autorelease];
	[buttonContainer addSubview:button];
	
	self.tableView.tableFooterView = buttonContainer;
	
	if ([self.recents count] == 0 || didBeginExternalSearchBeforeLoading) {
		self.tableView.tableFooterView.hidden = YES;
	}

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (didBeginExternalSearchBeforeLoading && self.searchTerms.length > 0 && self.searchResults == nil) {
		[self performSearch];
	} else {
		[self.tableView reloadData];
	}
}

// wrapper around [tableView reloadData] that makes sure
// we don't have anything artifically blocked from showing up 
// which we do when we are called externally
- (void)reloadIfDidExternalSearch {
	if (didBeginExternalSearchBeforeLoading) {
		didBeginExternalSearchBeforeLoading = NO;
		[self.tableView reloadData];
	}
}

#pragma mark memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[recentlyViewedHeader release];
	[recents release];
	[searchResults release];
	[searchTerms release];
	[searchTokens release];
	searchBackground.controller = nil;
	[searchBackground release];
	[searchController release];
	[loadingView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Search methods

- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	theSearchBar.text = self.searchTerms;
	[self.searchBackground removeFromSuperview];
	if ([self isViewLoaded]) {
		// we do the following because setting self.searchController.active
		// causes the translucent overlay to be displayed on top of the search results tableview
		[self.searchController.searchResultsTableView removeFromSuperview];
		[self.view addSubview:self.searchController.searchResultsTableView];
		
		[self performSearch];
	} else {
		didBeginExternalSearchBeforeLoading = YES;
	}
}

- (void)cancelSearch { // activated by clicking on searchBackground as opposed to cancel button
	[theSearchBar resignFirstResponder];
	[self.searchBackground removeFromSuperview];
	self.searchResults = nil;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	[self.searchBackground removeFromSuperview];
	if ([self.recents count] > 0)
		self.tableView.tableFooterView.hidden = NO;
	[self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
	// if they cancelled while waiting for loading
	if (requestWasDispatched) {
		[api abortRequest];
		[self cleanUpConnection];
	}

	[self reloadIfDidExternalSearch];
	[self.searchController.searchResultsTableView removeFromSuperview];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	// recreate their translucent overlay
	if (self.searchBackground == nil) {
		self.searchBackground = [[MITSearchEffects alloc]
								 initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, 
														  self.tableView.frame.size.width,
														  self.tableView.frame.size.width - theSearchBar.frame.size.height)];
		[self.searchBackground setController:self];
	}
	
	[self reloadIfDidExternalSearch];
	
	if ([searchText length] == 0)
		[self.searchBackground removeFromSuperview];
	else {
		[self.searchController.searchResultsTableView removeFromSuperview];
		
		if (![self.searchBackground isDescendantOfView:self.tableView]) {// && !didBeginExternalSearchBeforeLoading) {
			// make sure our overlay is the only one present when there's nonempty text
			for (UIView *view in self.tableView.subviews) {
				// not a robust way to check if this is the built-in overlay
				if ([view isKindOfClass:[UIControl class]] && view != self.searchBackground && view.frame.origin.x == 0) {
					[view removeFromSuperview];
					break;
				}
			}
			
			[self.tableView addSubview:self.searchBackground];
		}
			
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	self.searchTerms = searchString;
    return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
	// we will only, and always, receive this delegate message 
	// if search was initiated after our view was loaded in memory
	// so we turn off this flag here
	didBeginExternalSearchBeforeLoading = NO;
	// this will be shown by handleData
	tableView.hidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBackground removeFromSuperview];
	self.searchTerms = searchBar.text;
	[self performSearch];
}

- (void)performSearch
{
	// save search tokens for drawing table cells
	NSMutableArray *tempTokens = [NSMutableArray arrayWithArray:[[self.searchTerms lowercaseString] componentsSeparatedByString:@" "]];
	[tempTokens sortUsingFunction:strLenSort context:NULL]; // match longer tokens first
	self.searchTokens = [NSArray arrayWithArray:tempTokens];
	
	api = [MITMobileWebAPI jsonLoadedDelegate:self];
	requestWasDispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"people", @"module", self.searchTerms, @"q", nil]];
	
    if (requestWasDispatched) {
		[self showLoadingView];
    }
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchController.searchResultsTableView)
		return 1;
	else if (didBeginExternalSearchBeforeLoading)
		return 0; // so that the table doesn't draw anything above the loading indicator
	else if ([self.recents count] > 0)
		return 2;
	else
		return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.tableView) {
		switch (section) {
			case 0: // phone directory & emergency contacts
				return 2;
				break;
			case 1: // recently viewed
				return [self.recents count];
				break;
			default:
				return 0;
				break;
		}
	} else {
		return [self.searchResults count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *secondaryCellID = @"InfoCell";
	static NSString *recentCellID = @"RecentCell";

	if (tableView == self.tableView) { // show phone directory tel #, recents
	
	
		if (indexPath.section == 0) {
			
			SecondaryGroupedTableViewCell *cell = (SecondaryGroupedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:secondaryCellID];
			if (cell == nil) {
				cell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:secondaryCellID] autorelease];

				if (indexPath.row == 0) {
					cell.textLabel.text = @"Phone Directory";
					cell.secondaryTextLabel.text = @"(617.253.1000)";
					cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
				} else {
					cell.textLabel.text = @"Emergency Contacts";
					cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmergency];
				}
			}
			
			return cell;
		
		} else { // recents
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recentCellID];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:recentCellID] autorelease];
			}
			
			[cell applyStandardFonts];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			PersonDetails *recent = [self.recents objectAtIndex:indexPath.row];
			cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [recent valueForKey:@"givenname"], [recent valueForKey:@"surname"]];
			
			// show person's title, dept, or email as cell's subtitle text
			cell.detailTextLabel.text = @" "; // put something there so other cells' contents won't get drawn here
			NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"dept", nil];
			NSString *displayText;
			for (NSString *tag in displayPriority) {
				if (displayText = [recent valueForKey:tag]) {
					cell.detailTextLabel.text = displayText;
					break;
				}
			}
			
			return cell;
		}
		
	} else { // search results
		
		PartialHighlightTableViewCell *cell = (PartialHighlightTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
		if (cell == nil) {
			cell = [[[PartialHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
			
		NSDictionary *searchResult = [self.searchResults objectAtIndex:indexPath.row];
		NSString *fullname = [[searchResult objectForKey:@"name"] objectAtIndex:0];
		
		// figure out which field (if any) to display as subtitle
		// display priority: title, dept
		cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
		NSArray *detailAttribute = nil;
		if ((detailAttribute = [searchResult objectForKey:@"title"]) != nil) {
			cell.detailTextLabel.text = [detailAttribute objectAtIndex:0];
		} else if ((detailAttribute = [searchResult objectForKey:@"title"]) != nil) {
			cell.detailTextLabel.text = [detailAttribute objectAtIndex:0];
		}
		
		// in this section we try to highlight the parts of the results that match the search terms
		// temporarily place "normal[bold] [bold]normal" as textlabel
		// PartialHightlightTableViewCell will change bracketed text to bold text		
		NSString *preformatString = [NSString stringWithString:fullname];
		NSRange boldRange;
		NSInteger tokenIndex = 0; // if this is the first token we don't need to do the [ vs ] comparison
		for (NSString *token in self.searchTokens) {
			boldRange = [[preformatString lowercaseString] rangeOfString:token];
			if (boldRange.location != NSNotFound) {
				// if range is already bracketed don't create another pair inside
				NSString *leftString = [preformatString substringWithRange:NSMakeRange(0, boldRange.location)];
				if ((tokenIndex > 0) && [[leftString componentsSeparatedByString:@"["] count] > [[leftString componentsSeparatedByString:@"]"] count])
						continue;
				
				preformatString = [NSString stringWithFormat:@"%@[%@]%@",
								   leftString,
								   [preformatString substringWithRange:boldRange],
								   [preformatString substringFromIndex:(boldRange.location + boldRange.length)]];
			}
			tokenIndex++;
		}
		
		cell.textLabel.text = preformatString;

		
		return cell;
	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView && indexPath.section == 0) {
		return 44.0;
	} else {
		return CELL_TWO_LINE_HEIGHT;
	}
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
	
	if (section == 1)
		title = @"Recently Viewed";
	else if (tableView == self.searchController.searchResultsTableView) {
		if ([self.searchResults count] == 1)
			title = [NSString stringWithString:@"1 result found"];
		else
			title = [NSString stringWithFormat:@"%d results found", [self.searchResults count]];
	}
	
    return title;
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return GROUPED_SECTION_HEADER_HEIGHT;
	} else if (tableView == self.searchController.searchResultsTableView && [self.searchResults count] > 0) {
		return UNGROUPED_SECTION_HEADER_HEIGHT;
	} else {
		return 0.0;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
	
	if (section == 1) {
		if (recentlyViewedHeader == nil) {
			recentlyViewedHeader = [[UITableView groupedSectionHeaderWithTitle:@"Recently Viewed"] retain];
		}
		titleView = recentlyViewedHeader;
	} else if (tableView == self.searchController.searchResultsTableView) {
		NSUInteger numResults = [self.searchResults count];
		switch (numResults) {
			case 0:
				break;
			case 1:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:@"1 result found"];		
				break;
			case 100:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:@"Many results found, showing 100"];
				break;
			default:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d results found", numResults]];
				break;
		}
	}
	
    return titleView;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (tableView == self.searchController.searchResultsTableView || indexPath.section == 1) { // user selected search result or recently viewed

		PersonDetails *personDetails;
		PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		if (tableView == self.searchController.searchResultsTableView) {
			NSDictionary *selectedResult = [self.searchResults objectAtIndex:indexPath.row];
			personDetails = [PersonDetails retrieveOrCreate:selectedResult];
		} else {
			personDetails = [self.recents objectAtIndex:indexPath.row];
		}
		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
		[detailView release];
		
	} else { // we are on home screen and user selected phone or emergency contacts
		
		switch (indexPath.row) {
			case 0:
				[self phoneIconTapped];				
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
				break;
			case 1: // push emergency contacts
			{
                [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:EmergencyTag path:@"contacts"]];
				[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
				break;
			}
		}
	}
}

#pragma mark -
#pragma mark Connection methods

- (void)showLoadingView {
	// manually add loading view because we're not using the built-in data source table
	if (self.loadingView == nil) {
		self.loadingView = [[MITLoadingActivityView alloc] initWithFrame:[MITSearchEffects frameWithHeader:self.tableView.tableFooterView]];
	}
	
	[self.tableView addSubview:self.loadingView];
}

- (void)cleanUpConnection {
	requestWasDispatched = NO;
	[self.loadingView removeFromSuperview];	
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
    [self cleanUpConnection];
	
	if (result && [result isKindOfClass:[NSArray class]]) {
		self.searchResults = result;
	} else {
		self.searchResults = nil;
	}
	
	if (!self.searchController.active) {
		[self.searchController setActive:YES];
		[self.searchController.searchResultsTableView removeFromSuperview];
	}

	if (![self.searchController.searchResultsTableView isDescendantOfView:self.view]) {
		[self.view addSubview:self.searchController.searchResultsTableView];
	}
	
	self.searchController.searchResultsTableView.hidden = NO;
	[self.searchController.searchResultsTableView reloadData];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	[self cleanUpConnection];	
	[self reloadIfDidExternalSearch];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection failed" 
													 message:@"Either we are not connected or the connection timed out.  Please try again later."
													delegate:self
										   cancelButtonTitle:@"OK" 
										   otherButtonTitles:nil];
	[alert show];
	[self cancelSearch];
	[alert release];
}

#pragma mark -
#pragma mark Action sheet methods

- (void)showActionSheet
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Clear Recents?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:nil];
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[UIApplication sharedApplication].delegate;
    [sheet showFromTabBar:appDelegate.tabBarController.tabBar];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"]) {
		[PeopleRecentsData eraseAll];
		self.tableView.tableFooterView.hidden = YES;
		[self.tableView reloadData];
		[self.tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
	}
}
/*
#pragma mark Alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [alertView cancelButtonIndex]) { // user hit "Dial"
		NSURL *externURL = [NSURL URLWithString:@"tel://6172531000"];
		[[UIApplication sharedApplication] openURL:externURL];
	}
}
*/
- (void)phoneIconTapped
{
	NSURL *externURL = [NSURL URLWithString:@"tel://6172531000"];
	if ([[UIApplication sharedApplication] canOpenURL:externURL])
		[[UIApplication sharedApplication] openURL:externURL];
	
	/*
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Dial 6172531000?" 
													 message:@"" 
													delegate:self
										   cancelButtonTitle:@"Cancel" 
										   otherButtonTitles:@"Dial", nil] autorelease];
	[alert show];
	*/
}


@end

