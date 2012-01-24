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

@synthesize searchTerms, searchTokens, searchResults, searchController,
loadingView, searchBar = theSearchBar, tableView = theTableView;;

#pragma mark view

- (void)viewDidLoad {
	[super viewDidLoad];
    self.title = @"People Directory";
    
	requestWasDispatched = NO;
	
	// set up search bar
	theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)];
    theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	
	//theSearchBar.delegate = self;
	theSearchBar.placeholder = @"Search";
	if ([self.searchTerms length] > 0)
		theSearchBar.text = self.searchTerms;
    
    // set up search controller
    self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self] autorelease];
	self.searchController.delegate = self;
    
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height, theSearchBar.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height);
    searchResultsTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.searchController.searchResultsTableView = searchResultsTableView;
    self.searchController.searchResultsDelegate = self;
    self.searchController.searchResultsDataSource = self;
    
    // set up tableview
    self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	
	[self.tableView applyStandardColors];
	
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
	UIView *hintsContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, labelSize.width, labelSize.height + 10.0)];
	[hintsContainer addSubview:hintsLabel];
	[hintsLabel release];
    
	self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:hintsContainer.frame] autorelease];
	[self.tableView.tableHeaderView addSubview:hintsContainer];
	[hintsContainer release];

	// set up screen for when there are no results
	recentlyViewedHeader = nil;
	
	// set up table footer
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(10.0, 0.0, self.tableView.frame.size.width - 20.0, 44.0)];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
	[button setTitle:@"Clear Recents" forState:UIControlStateNormal];
	
	// based on code from stackoverflow.com/questions/1427818/iphone-sdk-creating-a-big-red-uibutton
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[[UIImage imageNamed:@"people/redbutton2highlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
					  forState:UIControlStateHighlighted];
	
	[button addTarget:self action:@selector(showActionSheet) forControlEvents:UIControlEventTouchUpInside];	
	
	UIView *buttonContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 44.0)] autorelease];
	[buttonContainer addSubview:button];
	
	self.tableView.tableFooterView = buttonContainer;
    
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    if (![self.searchController isActive]) {
        [self.tableView reloadData];
    } else {
        [searchResultsTableView deselectRowAtIndexPath:[searchResultsTableView indexPathForSelectedRow] animated:YES];
    }
    self.tableView.tableFooterView.hidden = ([[[PeopleRecentsData sharedData] recents] count] == 0);
}

#pragma mark memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[recentlyViewedHeader release];
	[searchResults release];
	[searchTerms release];
	[searchTokens release];
	[searchController release];
    [theTableView release];
	[loadingView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Search methods

- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	theSearchBar.text = self.searchTerms;
	
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
	// if they cancelled while waiting for loading
	if (requestWasDispatched) {
		[api abortRequest];
		[self cleanUpConnection];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
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
	else if ([[[PeopleRecentsData sharedData] recents] count] > 0)
		return 2;
	else
		return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.tableView) {
		switch (section) {
			case 0: // phone directory & emergency contacts
				return 2;
				break;
			case 1: // recently viewed
				return [[[PeopleRecentsData sharedData] recents] count];
				break;
			default:
				return 0;
				break;
		}
	} else {
		return [self.searchResults count];
	}
}

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

			PersonDetails *recent = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
			cell.textLabel.text = [recent displayName];
            
			// show person's title, dept, or email as cell's subtitle text
			cell.detailTextLabel.text = @" "; // put something there so other cells' contents won't get drawn here
			NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"dept", nil];
			NSString *displayText;
			for (NSString *tag in displayPriority) {
				displayText = [recent valueForKey:tag];
				if (displayText) {
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
		} else if ((detailAttribute = [searchResult objectForKey:@"dept"]) != nil) {
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
        if (requestWasDispatched) {
            return nil;
        }
        
		if (recentlyViewedHeader == nil) {
			recentlyViewedHeader = [[UITableView groupedSectionHeaderWithTitle:@"Recently Viewed"] retain];
		}
		titleView = recentlyViewedHeader;
	} else if (tableView == self.searchController.searchResultsTableView) {
		NSUInteger numResults = [self.searchResults count];
		switch (numResults) {
			case 0:
				break;
			case 100:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:@"Many found, showing 100"];
				break;
			default:
				titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", numResults]];
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
			personDetails = [[[PeopleRecentsData sharedData] recents] objectAtIndex:indexPath.row];
		}
		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
		[detailView release];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
		
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
	if (self.loadingView == nil) {
        CGRect frame = CGRectMake(0.0, self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height);
		self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:frame] autorelease];
	}
	
	[self.view addSubview:self.loadingView];
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

    self.searchController.searchResultsTableView.frame = self.tableView.frame;
    [self.view addSubview:self.searchController.searchResultsTableView];
	[self.searchController.searchResultsTableView reloadData];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	[self cleanUpConnection];
}

- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Directory";
}

#pragma mark -
#pragma mark Action sheet methods

- (void)showActionSheet
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Clear Recents?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"Clear"
                                              otherButtonTitles:nil];
    [sheet showFromAppDelegate];
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

- (void)phoneIconTapped
{
	NSURL *externURL = [NSURL URLWithString:@"tel://6172531000"];
	if ([[UIApplication sharedApplication] canOpenURL:externURL])
		[[UIApplication sharedApplication] openURL:externURL];
}


@end

