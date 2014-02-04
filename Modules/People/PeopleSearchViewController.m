#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
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

#import "MITPeopleResource.h"

@interface PeopleSearchViewController () <UISearchBarDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic,strong) IBOutlet UITableView *searchResultsTableView;
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

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.view.backgroundColor = [UIColor mit_backgroundColor];

    UITableView *searchTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	searchTableView.backgroundColor = [UIColor mit_backgroundColor];
    self.searchResultsTableView = searchTableView;

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    if (![self.searchDisplayController isActive]) {
        [self.tableView reloadData];
    } else {
        [self.searchResultsTableView deselectRowAtIndexPath:[self.searchResultsTableView indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark -
#pragma mark Search methods

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ([self.searchResults count]) {
        self.searchDisplayController.searchResultsTableView.hidden = NO;
    }
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (![searchBar.text length]) {
        self.searchResults = nil;
        _searchCancelled = YES;
        [self.searchResultsTableView reloadData];
    }
}

- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;
	self.searchBar.text = self.searchTerms;
	
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.searchResults = nil;
    self.searchCancelled = YES;
    [self.searchBar resignFirstResponder];
    [self.searchDisplayController setActive:NO];
    self.searchDisplayController.searchResultsTableView.hidden = YES;
    if (self.loadingView.superview) {
        [self.loadingView removeFromSuperview];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.searchTerms = searchBar.text;
	[self performSearch];
    [self.searchBar resignFirstResponder];
}

- (void)performSearch
{
	// save search tokens for drawing table cells
	NSMutableArray *tempTokens = [NSMutableArray arrayWithArray:[[self.searchTerms lowercaseString] componentsSeparatedByString:@" "]];
	[tempTokens sortUsingComparator:^NSComparisonResult(NSString *string1, NSString *string2) {
        return [@([string1 length]) compare:@([string2 length])];
    }];
    
	self.searchTokens = tempTokens;
    
    [MITPeopleResource peopleMatchingQuery:self.searchTerms loaded:^(NSArray *objects, NSError *error) {
        if (!error && !_searchCancelled) {
            // if there is no error and the search is not cancelled
            self.searchResults = objects;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        [self.loadingView removeFromSuperview];
    }];
    self.searchResultsTableView.hidden = NO;
    [self showLoadingView];

	_searchCancelled = NO;
}
#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return 1;
	else if ([[[PeopleRecentsData sharedData] recents] count] > 0)
		return 2;
	else
		return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.tableView) {
		switch (section) {
			case 0: // sample cell, phone directory, & emergency contacts
				return 3;
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
    
	static NSString *recentCellID = @"RecentCell";
    
    static NSString * directoryAssistanceID = @"DirectoryAssistanceCell";

	if (tableView == self.tableView) { // show phone directory tel #, recents
	
	
		if (indexPath.section == 0) {
			
            UITableViewCell *cell;
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"SampleCell" forIndexPath:indexPath];
            } else if (indexPath.row == 1) {
                cell = [tableView dequeueReusableCellWithIdentifier:directoryAssistanceID forIndexPath:indexPath];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            } else if (indexPath.row == 2) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"EmergencyContactsCell" forIndexPath:indexPath];
//                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmergency];
            }
			
			return cell;
		
		} else { // recents
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:recentCellID forIndexPath:indexPath];

			PersonDetails *recent = [[PeopleRecentsData sharedData] recents][indexPath.row];
			cell.textLabel.text = recent.name;
            
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
		UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
			
		PersonDetails *searchResult = self.searchResults[indexPath.row];
		NSString *fullname = searchResult.name;

		if (searchResult.title) {
			cell.detailTextLabel.text = searchResult.title;
		} else if (searchResult.dept) {
			cell.detailTextLabel.text = searchResult.dept;
		} else {
            cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
        }
		
        
		// in this section we try to highlight the parts of the results that match the search terms
        UIFont *labelFont = cell.textLabel.font;
        UIFont *boldFont = [UIFont boldSystemFontOfSize:labelFont.pointSize];   // This assumes labelFont will be using the systemFont
        __block NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:fullname];
        [self.searchTokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger idx, BOOL *stop) {
            NSRange boldRange = [[fullname lowercaseString] rangeOfString:token];
			if (boldRange.location != NSNotFound) {
				[attributeString addAttribute:NSFontAttributeName value:boldFont range:boldRange];
			}
        }];
		
		cell.textLabel.attributedText = attributeString;
		return cell;
	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView && indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 88.0;
        }
		return 44.0;
	} else {
		return CELL_TWO_LINE_HEIGHT;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return GROUPED_SECTION_HEADER_HEIGHT;
	} else if (tableView == self.searchDisplayController.searchResultsTableView && [self.searchResults count] > 0) {
		return UNGROUPED_SECTION_HEADER_HEIGHT;
	} else {
		return 0.0;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return [UITableView groupedSectionHeaderWithTitle:@"Recently Viewed"];
	} else if (tableView == self.searchDisplayController.searchResultsTableView) {
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
	if (tableView == self.searchDisplayController.searchResultsTableView) { // user selected search result
		PersonDetails *personDetails = nil;
        
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"People" bundle:nil];
        PeopleDetailsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"PeopleDetailsVC"];
		if (tableView == self.searchDisplayController.searchResultsTableView) {
			personDetails = self.searchResults[indexPath.row];
		} else {
			personDetails = [[PeopleRecentsData sharedData] recents][indexPath.row];
		}

		vc.personDetails = personDetails;
		[self.navigationController pushViewController:vc animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark - Connection methods

- (void)showLoadingView {
	if (!self.loadingView) {
        CGRect frame = self.tableView.bounds;
        frame.origin.y = CGRectGetMaxY(self.searchBar.frame);
        frame.size.height -= frame.origin.y;

		MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:frame];
        self.loadingView = loadingView;
	}
    [self.view addSubview:self.loadingView];
}

#pragma mark - Storyboard Segues
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showPerson"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        PersonDetails *personDetails = [[PeopleRecentsData sharedData] recents][indexPath.row];
        PeopleDetailsViewController *vc = (PeopleDetailsViewController *)segue.destinationViewController;
        vc.personDetails = personDetails;
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

