#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PartialHighlightTableViewCell.h"
#import "MIT_MobileAppDelegate.h"
#import "ConnectionDetector.h"
#import "MobileRequestOperation.h"
// common UI elements
#import "MITLoadingActivityView.h"
#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"
// external modules
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface PeopleSearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UITableView *searchResultsTableView;
@property (nonatomic,strong) UIView *loadingView;
@property (nonatomic,strong) UIView *recentlyViewedHeader;

@property (nonatomic,copy) NSString *searchTerms;
@property (nonatomic,copy) NSArray *searchTokens;

@property (strong) NSURL *directoryPhoneURL;
@property BOOL searchCancelled;
@end

@implementation PeopleSearchViewController
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil
                           bundle:nil];
    
    if (self) {
        self.directoryPhoneURL = [NSURL URLWithString:@"telprompt://617.253.1000"];
    }
    
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)loadView
{
    UIView *view = [self defaultApplicationView];
    view.backgroundColor = [UIColor mit_backgroundColor];

    self.view = view;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    self.title = @"People Directory";
    
	// set up search bar
    {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0., self.view.frame.size.width, NAVIGATION_BAR_HEIGHT)];
        searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        searchBar.placeholder = @"Search";

        if ([self.searchTerms length]) {
            searchBar.text = self.searchTerms;
        }

        [self.view addSubview:searchBar];
        self.searchBar = searchBar;
    }

    // set up search controller
    self.searchController = [[MITSearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
	self.searchController.delegate = self;

    CGRect tablesFrame = CGRectMake(0.0,
                                    CGRectGetMaxY(self.searchBar.frame),
                                    self.searchBar.frame.size.width,
                                    self.view.frame.size.height - CGRectGetMaxY(self.searchBar.frame));
    UITableView *searchTableView = [[UITableView alloc] initWithFrame:tablesFrame style:UITableViewStylePlain];
	searchTableView.backgroundView.backgroundColor = [UIColor mit_backgroundColor];
    
    self.searchController.searchResultsTableView = searchTableView;
    self.searchController.searchResultsDelegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchResultsTableView = searchTableView;

    // set up tableview
    UITableView *tableView = [[UITableView alloc] initWithFrame:tablesFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
	tableView.backgroundView.backgroundColor = [UIColor mit_backgroundColor];

    NSString *searchHints = @"Sample searches:\nName: 'william barton rogers', 'rogers'\nEmail: 'wbrogers', 'wbrogers@mit.edu'\nPhone: '6172531000', '31000'";
	UIFont *hintsFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	CGSize labelSize = [searchHints sizeWithFont:hintsFont
									constrainedToSize:tableView.frame.size
										lineBreakMode:NSLineBreakByWordWrapping];
	
	UILabel *hintsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, labelSize.width, labelSize.height + 5.0)];
	hintsLabel.numberOfLines = 0;
	hintsLabel.backgroundColor = [UIColor clearColor];
	hintsLabel.lineBreakMode = NSLineBreakByWordWrapping;
	hintsLabel.font = hintsFont;
	hintsLabel.text = searchHints;	
	UIView *hintsContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, labelSize.width, labelSize.height + 10.0)];
	[hintsContainer addSubview:hintsLabel];
	tableView.tableHeaderView = hintsContainer;
	
	// set up table footer
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(10.0, 0.0, tableView.frame.size.width - 20.0, 44.0)];
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
        
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 44.0)];
        [buttonContainer addSubview:button];
        tableView.tableFooterView = buttonContainer;
    }
	
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    if (![self.searchController isActive]) {
        [self.tableView reloadData];
    } else {
        [self.searchResultsTableView deselectRowAtIndexPath:[self.searchResultsTableView indexPathForSelectedRow] animated:YES];
    }
    self.tableView.tableFooterView.hidden = ([[[PeopleRecentsData sharedData] recents] count] == 0);
}

#pragma mark -
#pragma mark Search methods

- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	self.searchBar.text = self.searchTerms;
	
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
    self.searchCancelled = YES;
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
	[tempTokens sortUsingComparator:^NSComparisonResult(NSString *string1, NSString *string2) {
        return [@([string1 length]) compare:@([string2 length])];
    }];
    
	self.searchTokens = tempTokens;

    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"people"
                                                                              command:nil
                                                                          parameters:@{@"q" : self.searchTerms}];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (_searchCancelled) {
            return;
        }
        
        [self.loadingView removeFromSuperview];	
        if (!error) {
            if ([jsonResult isKindOfClass:[NSArray class]]) {
                self.searchResults = jsonResult;
            } else {
                self.searchResults = nil;
            }
            
            self.searchController.searchResultsTableView.frame = self.tableView.frame;
            [self.view addSubview:self.searchController.searchResultsTableView];
            [self.searchController.searchResultsTableView reloadData];    
        }
    };

    [self showLoadingView];

	_searchCancelled = NO;
    [[NSOperationQueue mainQueue] addOperation:request];
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
				cell = [[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:secondaryCellID];
			}
            
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Phone Directory";
                cell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@)",[self.directoryPhoneURL host]];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            } else {
                cell.textLabel.text = @"Emergency Contacts";
                cell.secondaryTextLabel.text = nil;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmergency];
            }
			
			return cell;
		
		} else { // recents
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recentCellID];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:recentCellID];
                [cell applyStandardFonts];
			}

			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			PersonDetails *recent = [[PeopleRecentsData sharedData] recents][indexPath.row];
			cell.textLabel.text = [recent displayName];
            
			// show person's title, dept, or email as cell's subtitle text
			cell.detailTextLabel.text = @" ";
			NSString *displayText = nil;
			for (NSString *tag in @[@"title", @"dept"]) {
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
		if (!cell) {
			cell = [[PartialHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
			
		NSDictionary *searchResult = self.searchResults[indexPath.row];
		NSString *fullname = searchResult[@"name"][0];

		if (searchResult[@"title"]) {
			cell.detailTextLabel.text = searchResult[@"title"][0];
		} else if (searchResult[@"dept"]) {
			cell.detailTextLabel.text = searchResult[@"dept"][0];
		} else {
            cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
        }
		
		// in this section we try to highlight the parts of the results that match the search terms
		// temporarily place "normal[bold] [bold]normal" as textlabel
		// PartialHightlightTableViewCell will change bracketed text to bold text
		__block NSString *preformatString = [NSString stringWithString:fullname];
        [self.searchTokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger idx, BOOL *stop) {
            NSRange boldRange = [[preformatString lowercaseString] rangeOfString:token];
			if (boldRange.location != NSNotFound) {
				// if range is already bracketed don't create another pair inside
				NSString *leftString = [preformatString substringWithRange:NSMakeRange(0, boldRange.location)];
				if (!((idx > 0) && [[leftString componentsSeparatedByString:@"["] count] > [[leftString componentsSeparatedByString:@"]"] count])) {
                    preformatString = [NSString stringWithFormat:@"%@[%@]%@",
                                       leftString,
                                       [preformatString substringWithRange:boldRange],
                                       [preformatString substringFromIndex:(boldRange.location + boldRange.length)]];
                }
			}
        }];
		
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
	if (section == 1) {
		return [UITableView groupedSectionHeaderWithTitle:@"Recently Viewed"];
	} else if (tableView == self.searchController.searchResultsTableView) {
		NSUInteger numResults = [self.searchResults count];
		switch (numResults) {
			case 0:
				break;
			case 100:
				return [UITableView ungroupedSectionHeaderWithTitle:@"Many found, showing 100"];
				break;
			default:
				return [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", numResults]];
				break;
		}
	}
	
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.searchController.searchResultsTableView || indexPath.section == 1) { // user selected search result or recently viewed
		PersonDetails *personDetails = nil;
        
		PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		if (tableView == self.searchController.searchResultsTableView) {
			personDetails = [PersonDetails retrieveOrCreate:self.searchResults[indexPath.row]];
		} else {
			personDetails = [[PeopleRecentsData sharedData] recents][indexPath.row];
		}

		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
	} else { // we are on home screen and user selected phone or emergency contacts
		switch (indexPath.row) {
			case 0:
				[self phoneIconTapped];				
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
				break;
			case 1:
                [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:EmergencyTag path:@"contacts"]];
				[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
				break;
		}
	}
}

#pragma mark - Connection methods

- (void)showLoadingView {
	if (!self.loadingView) {
        CGRect frame = self.searchBar.frame;
        frame.origin.x = 0.0;
        frame.size.height = CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.searchBar.frame);

		MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:frame];
        [self.view addSubview:loadingView];
        self.loadingView = loadingView;
	}
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
	if ([[UIApplication sharedApplication] canOpenURL:self.directoryPhoneURL])
		[[UIApplication sharedApplication] openURL:self.directoryPhoneURL];
}


@end

