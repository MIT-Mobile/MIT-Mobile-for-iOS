#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "MIT_MobileAppDelegate.h"
#import "ConnectionDetector.h"
#import "MobileRequestOperation.h"
// common UI elements
#import "MITLoadingActivityView.h"
// external modules
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

#import "MITPeopleResource.h"

typedef NS_ENUM(NSInteger, MITPeopleSearchTableViewSection) {
    MITPeopleSearchTableViewSectionExample = 0,
    MITPeopleSearchTableViewSectionContacts = 1,
    MITPeopleSearchTableViewSectionRecentlyViewed = 2
};

// Hard-code this for now, should be pulled from the API in the future
static NSString* const MITPeopleDirectoryAssistancePhone = @"617.253.1000";

@interface PeopleSearchViewController () <UISearchBarDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic,weak) UITableView *searchResultsTableView;
@property (nonatomic,weak) MITLoadingActivityView *searchResultsLoadingView;

@property (nonatomic,strong) UIView *recentlyViewedHeader;

@property (nonatomic,copy) NSString *searchTerms;
@property (nonatomic,copy) NSArray *searchTokens;

@property BOOL searchCancelled;
@end

@implementation PeopleSearchViewController
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil
                           bundle:nil];
    
    if (self) {
        
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

    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];

        self.searchBar.tintColor = [UIColor MITTintColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    if ([self.searchDisplayController isActive]) {
        NSIndexPath *selectedRow = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        if (selectedRow && self.clearsSelectionOnViewWillAppear) {
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selectedRow animated:animated];
        }
    } else {
        [self.tableView reloadData];
    }
}

#pragma mark - Search methods
#pragma mark UISearchDisplay Delegate
- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    if (self.searchTerms) {
        controller.searchBar.text = self.searchTerms;
        [self performSearch];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return NO;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self.tableView reloadData];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searchTerms = nil;
    self.searchTokens = nil;
    self.searchResults = nil;
    [self.searchResultsLoadingView removeFromSuperview];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchBar.text length] <= 0) {
        self.searchResults = nil;
        self.searchTerms = nil;
        self.searchCancelled = YES;
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.searchTerms = searchBar.text;
	[self performSearch];
}


- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchTerms = externalSearchTerms;

    if ([self.searchDisplayController isActive]) {
        self.searchDisplayController.searchBar.text = externalSearchTerms;
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self performSearch];
    } else {
        [self.searchDisplayController setActive:YES animated:YES];
    }
}

- (void)performSearch
{
	// save search tokens for drawing table cells
    NSString *searchQuery = [self.searchTerms lowercaseString];
    NSArray *searchTokens = [searchQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    searchTokens = [searchTokens sortedArrayUsingComparator:^NSComparisonResult(NSString *string1, NSString *string2) {
        return [@([string1 length]) compare:@([string2 length])];
    }];

	self.searchTokens = searchTokens;
	self.searchCancelled = NO;

    NSString *currentQueryString = self.searchTerms;
    __weak PeopleSearchViewController *weakSelf = self;
    [MITPeopleResource peopleMatchingQuery:currentQueryString loaded:^(NSArray *objects, NSError *error) {
        PeopleSearchViewController *blockSelf = weakSelf;
        if (blockSelf) {
            if (error) {
                blockSelf.searchResults = nil;
                [blockSelf.searchDisplayController.searchResultsTableView reloadData];

            } else if (!blockSelf.searchCancelled && (blockSelf.searchTerms == currentQueryString)) {
                blockSelf.searchResults = objects;
                [blockSelf.searchDisplayController.searchResultsTableView reloadData];
            }

            [blockSelf.searchResultsLoadingView removeFromSuperview];
        }
    }];

    [self showLoadingView];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        if ([[[PeopleRecentsData sharedData] recents] count] > 0) {
            return 3; // Examples + Directory Assistance/Contacts + Recents
        } else {
            return 2; // Examples + Directory Assistance/Contacts, no recents
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.tableView) {
        MITPeopleSearchTableViewSection tableViewSection = section;
		switch (tableViewSection) {
            case MITPeopleSearchTableViewSectionExample: // sample cell
                return 1;
			case MITPeopleSearchTableViewSectionContacts: // phone directory, & emergency contacts
				return 2;
			case MITPeopleSearchTableViewSectionRecentlyViewed: // recently viewed
				return [[[PeopleRecentsData sharedData] recents] count];
			default:
				return 0;
		}
	} else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return ([self.searchResults count] ? [self.searchResults count] : 1); //Force a single row
	} else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *recentCellID = @"RecentCell";
    static NSString * directoryAssistanceID = @"DirectoryAssistanceCell";

    UITableViewCell *cell = nil;

	if (tableView == self.tableView) { // show phone directory tel #, recents
        if (MITPeopleSearchTableViewSectionExample == indexPath.section) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SampleCell" forIndexPath:indexPath];

            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, CGRectGetWidth(tableView.bounds));
            }
        } else if (MITPeopleSearchTableViewSectionContacts == indexPath.section) {
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:directoryAssistanceID forIndexPath:indexPath];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                
                // Overwrite whatever text there is in the prototyped cell (even if it's correct)
                // and replace it with our local value. Eventually, this information should be
                // pulled from the server instead of a constant.
                cell.detailTextLabel.text = MITPeopleDirectoryAssistancePhone;
            } else if (indexPath.row == 1) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"EmergencyContactsCell" forIndexPath:indexPath];
            }
        } else if (MITPeopleSearchTableViewSectionRecentlyViewed == indexPath.section) {
            cell = [tableView dequeueReusableCellWithIdentifier:recentCellID forIndexPath:indexPath];

            NSArray *recentPeople = [[PeopleRecentsData sharedData] recents];
            if (indexPath.row < [recentPeople count]) {
                PersonDetails *recent = recentPeople[indexPath.row];
                cell.textLabel.text = recent.name;

                // show person's title, dept, or email as cell's subtitle text
                // Setting the detailTextLabel's text to a space solves 2 issues:
                //  * Top-aligns the primary text field
                //  * In the case of cell reuse, clears out the detail field in case
                //      the person we are currently display does not have values for
                //      the below tags.
                cell.detailTextLabel.text = @" ";
                NSString *displayText = nil;
                for (NSString *tag in @[@"title", @"dept"]) {
                    displayText = [recent valueForKey:tag];
                    if (displayText) {
                        cell.detailTextLabel.text = displayText;
                        break;
                    }
                }
            }
        }

        return cell;
	} else if (tableView == self.searchDisplayController.searchResultsTableView) { // search results
		cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];

		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
		}

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // Make sure to sanity check the current row. Since tableView:numberOfRowsInSection:
        //  returns a minimum value of 1 (even if there are no actual results). If the table
        //  view is asking for a cell and we don't have anything to display, just return a blank cell
        // (bskinner - 2014.02.27)
        if (indexPath.row < [self.searchResults count]) {
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
                NSRange boldRange = [fullname rangeOfString:token options:NSCaseInsensitiveSearch];

                if (boldRange.location != NSNotFound) {
                    [attributeString setAttributes:@{NSFontAttributeName : boldFont} range:boldRange];
                }
            }];
            
            cell.textLabel.attributedText = attributeString;
        } else {
            // Clear out the text fields in the event of cell reuse
            // Needs to be done if there is not a valid person object for this row
            // because we may be displaying an empty cell (for example, in search results
            // to suppress the "No Results" text)
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.hidden = YES;
        }

        return cell;
	} else {
        return nil;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView) {
        MITPeopleSearchTableViewSection section = indexPath.section;

        if (MITPeopleSearchTableViewSectionExample == section) {
            return 86.;
        } else if (MITPeopleSearchTableViewSectionContacts == section) {
            switch (indexPath.row) {
                case 0: // Directory Assistance
                    return 60.;
                case 1: // Emergency Contacts
                    return 44.;
                default:
                     // There shouldn't be anything else in this section but, just in case
                    return UITableViewAutomaticDimension;
            }
        } else if (MITPeopleSearchTableViewSectionRecentlyViewed == section) {
            return UITableViewAutomaticDimension;
        }
	} else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return UITableViewAutomaticDimension;
	}

    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (MITPeopleSearchTableViewSectionRecentlyViewed == section) {
            return @"Recently Viewed";
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (MITPeopleSearchTableViewSectionContacts == indexPath.section) {
            switch (indexPath.row) {
                case 0:
                    // Call directory assistance!
                    [self phoneIconTapped];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
            }
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) { // user selected search result
		PersonDetails *personDetails = nil;

        // TODO: Switch to using the segues
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"People" bundle:nil];
        PeopleDetailsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"PeopleDetailsVC"];
		if (tableView == self.searchDisplayController.searchResultsTableView) {
			personDetails = self.searchResults[indexPath.row];
		} else {
			personDetails = [[PeopleRecentsData sharedData] recents][indexPath.row];
		}

		vc.personDetails = personDetails;
		[self.navigationController pushViewController:vc animated:YES];
	}
}

#pragma mark - Connection methods
- (void)showLoadingView {
    if (self.searchDisplayController.searchResultsTableView) {
        MITLoadingActivityView *loadingView = self.searchResultsLoadingView;
        if (!self.searchResultsLoadingView) {
            CGRect frame = self.searchDisplayController.searchResultsTableView.bounds;
            loadingView = [[MITLoadingActivityView alloc] initWithFrame:frame];

            self.searchResultsLoadingView = loadingView;
        }

        [self.searchDisplayController.searchResultsTableView addSubview:loadingView];
    }
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
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",MITPeopleDirectoryAssistancePhone]];
	if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
		[[UIApplication sharedApplication] openURL:phoneURL];
    }
}

@end

