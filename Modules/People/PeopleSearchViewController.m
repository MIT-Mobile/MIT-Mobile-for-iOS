#import "PeopleSearchViewController.h"
#import "PersonDetails.h"
#import "PeopleDetailsViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "ConnectionDetector.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
// common UI elements
#import "MITLoadingActivityView.h"
// external modules
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

#import "MITPeopleResource.h"
#import "MITPeopleSearchHandler.h"

#import "PeopleFavoriteData.h"
#import "PeopleRecentSearchTerm.h"
#import "MITPeopleRecentResultsViewController.h"

typedef NS_ENUM(NSInteger, MITPeopleSearchTableViewSection) {
    MITPeopleSearchTableViewSectionExample = 0,
    MITPeopleSearchTableViewSectionContacts = 1,
    MITPeopleSearchTableViewSectionFavorites = 2
};

// Hard-code this for now, should be pulled from the API in the future
static NSString* const MITPeopleDirectoryAssistancePhone = @"617.253.1000";

@interface PeopleSearchViewController () <UISearchBarDelegate, UIAlertViewDelegate, MITPeopleRecentsViewControllerDelegate>

@property (nonatomic,weak) UITableView *searchResultsTableView;
@property (nonatomic,weak) MITLoadingActivityView *searchResultsLoadingView;
@property (nonatomic, strong) NSArray *peopleFavorites;

@property (nonatomic, strong) MITPeopleSearchHandler *searchHandler;

@property (nonatomic, strong) MITPeopleRecentResultsViewController *recentResultsVC;

@property (nonatomic, assign) BOOL didBeginSearch;

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

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.searchHandler = [MITPeopleSearchHandler new];
    
    [self configureRecentResultsController];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    self.peopleFavorites = [PeopleFavoriteData retrieveFavoritePeople];
    
    if ([self.searchDisplayController isActive])
    {
        NSIndexPath *selectedRow = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        if (selectedRow && self.clearsSelectionOnViewWillAppear)
        {
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selectedRow animated:animated];
        }
        
        return;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self unregisterForKeyboardNotifications];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    
    CGFloat recentResultsViewHeight = self.view.frame.size.height - self.searchBar.frame.size.height - keyboardFrame.size.height - statusBarHeight;
    
    [self.recentResultsVC.view setFrame:CGRectMake(0,
                                                   self.searchBar.frame.size.height,
                                                   self.view.frame.size.width,
                                                   recentResultsViewHeight)];
}

#pragma mark - Search methods

- (void)performSearch
{
    [self setRecentResultsHidden:YES];
    
    [self.searchHandler addRecentSearchTerm:self.searchBar.text];
    
    __weak PeopleSearchViewController *weakSelf = self;
    [self.searchHandler performSearchWithCompletionHandler:^(BOOL isSuccess)
     {
         [weakSelf.searchDisplayController.searchResultsTableView reloadData];
         [weakSelf.searchResultsLoadingView removeFromSuperview];
     }];
    
    [self showLoadingView];
}

- (NSArray *)searchResults
{
    return self.searchHandler.searchResults;
}

#pragma mark - UISearchDisplay Delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    self.didBeginSearch = YES;
    
    [self setRecentResultsHidden:NO];
    
    if (self.searchHandler.searchTerms)
    {
        controller.searchBar.text = self.searchHandler.searchTerms;
        [self performSearch];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return NO;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self setRecentResultsHidden:YES];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searchHandler.searchTerms = nil;
    self.searchHandler.searchTokens = nil;
    self.searchHandler.searchResults = nil;
    [self.searchResultsLoadingView removeFromSuperview];
    
    self.didBeginSearch = NO;
}

#pragma mark UISearchBar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if( self.didBeginSearch )
    {
        [self setRecentResultsHidden:NO];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.recentResultsVC reloadRecentResultsWithFilterString:searchBar.text];
    
    if ([searchBar.text length] <= 0) {
        self.searchHandler.searchResults = nil;
        self.searchHandler.searchTerms = nil;
        self.searchHandler.searchCancelled = YES;
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        if( [self.searchBar isFirstResponder] )
        {
            [self setRecentResultsHidden:NO];
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.searchHandler.searchTerms = searchBar.text;
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    self.searchHandler.searchTerms = nil;
    self.searchHandler.searchTokens = nil;
    self.searchHandler.searchResults = nil;
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}


- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchHandler.searchTerms = externalSearchTerms;

    if ([self.searchDisplayController isActive]) {
        self.searchDisplayController.searchBar.text = externalSearchTerms;
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self performSearch];
    } else {
        [self.searchDisplayController setActive:YES animated:YES];
    }
}

#pragma mark - recents logic

- (void)configureRecentResultsController
{
    self.recentResultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"peopleRecentResults"];
    self.recentResultsVC.searchHandler = self.searchHandler;
    self.recentResultsVC.delegate = self;
    
    [self.recentResultsVC.view setFrame:CGRectZero];
    
    [self addChildViewController:self.recentResultsVC];
    [self.view addSubview:self.recentResultsVC.view];
    [self.recentResultsVC didMoveToParentViewController:self];
    
    [self setRecentResultsHidden:YES];
}

- (void)setRecentResultsHidden:(BOOL)isHidden
{
    [self.recentResultsVC.view setHidden:isHidden];
    
    if( !isHidden )
    {
        [self.recentResultsVC reloadRecentResultsWithFilterString:self.searchBar.text];
        [self.view bringSubviewToFront:self.recentResultsVC.view];
    }
}

- (void) didSelectRecentSearchTerm:(NSString *)searchTerm
{
    self.searchHandler.searchTerms = searchTerm;
    [self.searchBar setText:searchTerm];
    
    [self.searchBar resignFirstResponder];
    
    [self performSearch];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        if ([self.peopleFavorites count] > 0) {
            return 3; // Examples + Directory Assistance/Contacts + Favorites
        } else {
            return 2; // Examples + Directory Assistance/Contacts, no recents
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView)
    {
        return [self numberOfRowsInDefaultScreenSection:section];
	}
    else if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self.searchHandler.searchResults count];
	}
    else
    {
        return 0;
    }
}

- (NSInteger)numberOfRowsInDefaultScreenSection:(NSInteger)section
{
    MITPeopleSearchTableViewSection tableViewSection = section;
    switch (tableViewSection) {
        case MITPeopleSearchTableViewSectionExample: // sample cell
            return 1;
        case MITPeopleSearchTableViewSectionContacts: // phone directory, & emergency contacts
            return 2;
        case MITPeopleSearchTableViewSectionFavorites: // recently viewed
            return [self.peopleFavorites count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView)
    {
        // show phone directory tel #, recents
        return [self tableView:self.tableView cellForDefaultRowAtIndexPath:indexPath];
	}
    else if (tableView == self.searchDisplayController.searchResultsTableView) // search results
    {
        return [self tableView:self.tableView cellForSearchRowAtIndexPath:indexPath];
    }
    else
    {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSearchRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Make sure to sanity check the current row. Since tableView:numberOfRowsInSection:
    //  returns a minimum value of 1 (even if there are no actual results). If the table
    //  view is asking for a cell and we don't have anything to display, just return a blank cell
    // (bskinner - 2014.02.27)
    if (indexPath.row < [self.searchHandler.searchResults count]) {
        PersonDetails *searchResult = self.searchHandler.searchResults[indexPath.row];
        NSString *fullname = searchResult.name;
        
        if (searchResult.title) {
            cell.detailTextLabel.text = searchResult.title;
        } else if (searchResult.dept) {
            cell.detailTextLabel.text = searchResult.dept;
        } else {
            cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
        }
        
        
        // in this section we try to highlight the parts of the results that match the search terms
        cell.textLabel.attributedText = [self.searchHandler hightlightSearchTokenWithinString:fullname
                                                                                  currentFont:cell.textLabel.font];
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
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForDefaultRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *recentCellID = @"FavoriteCell";
    static NSString *directoryAssistanceID = @"DirectoryAssistanceCell";
    
    UITableViewCell *cell = nil;
    
    if (MITPeopleSearchTableViewSectionExample == indexPath.section)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SampleCell" forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, CGRectGetWidth(tableView.bounds));
    }
    else if (MITPeopleSearchTableViewSectionContacts == indexPath.section)
    {
        if (indexPath.row == 0)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:directoryAssistanceID forIndexPath:indexPath];
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            
            // Overwrite whatever text there is in the prototyped cell (even if it's correct)
            // and replace it with our local value. Eventually, this information should be
            // pulled from the server instead of a constant.
            cell.detailTextLabel.text = MITPeopleDirectoryAssistancePhone;
        }
        else if (indexPath.row == 1)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"EmergencyContactsCell" forIndexPath:indexPath];
        }
    }
    else if (MITPeopleSearchTableViewSectionFavorites == indexPath.section)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:recentCellID forIndexPath:indexPath];
        
        NSArray *favoritePeople = self.peopleFavorites;
        if (indexPath.row < [favoritePeople count])
        {
            PersonDetails *favorite = favoritePeople[indexPath.row];
            cell.textLabel.text = favorite.name;
            
            // show person's title, dept, or email as cell's subtitle text
            // Setting the detailTextLabel's text to a space solves 2 issues:
            //  * Top-aligns the primary text field
            //  * In the case of cell reuse, clears out the detail field in case
            //      the person we are currently display does not have values for
            //      the below tags.
            cell.detailTextLabel.text = @" ";
            NSString *displayText = nil;
            for (NSString *tag in @[@"title", @"dept"]) {
                displayText = [favorite valueForKey:tag];
                if (displayText) {
                    cell.detailTextLabel.text = displayText;
                    break;
                }
            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView) {
        MITPeopleSearchTableViewSection section = indexPath.section;

        if (MITPeopleSearchTableViewSectionExample == section)
        {
            return 86.;
        }
        else if (MITPeopleSearchTableViewSectionContacts == section)
        {
            switch (indexPath.row) {
                case 0: // Directory Assistance
                    return 60.;
                case 1: // Emergency Contacts
                    return 44.;
                default:
                     // There shouldn't be anything else in this section but, just in case
                    return UITableViewAutomaticDimension;
            }
        }
        else if (MITPeopleSearchTableViewSectionFavorites == section)
        {
            return 44.0;
        }
	}
    else if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        if ([self.searchHandler.searchResults count])
        {
            return 60.;
        }
	}

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (MITPeopleSearchTableViewSectionFavorites == section) {
            return @"Favorites";
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if (MITPeopleSearchTableViewSectionContacts == indexPath.section) {
            switch (indexPath.row) {
                case 0:
                    // Call directory assistance!
                    [self phoneIconTapped];
                    break;
            }
        }
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView)
    { // user selected search result

        [self performSegueWithIdentifier:@"showPerson" sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( MITPeopleSearchTableViewSectionFavorites == indexPath.section )
    {
        return YES;
    }
    
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        return;
    }
    
    NSUInteger numberOfRecentPeople = [self.peopleFavorites count];
    
    // shouldn't ever happen, but just a precaution to avoid any crashes in case of an error.
    if( indexPath.row >= numberOfRecentPeople )
    {
        return;
    }
    
    PersonDetails *favorite = self.peopleFavorites[indexPath.row];
    [PeopleFavoriteData setPerson:favorite asFavorite:NO];
    
    self.peopleFavorites = [PeopleFavoriteData retrieveFavoritePeople];
    
    //  a safety check to make sure deletion was successful
    if( [self.peopleFavorites count] >= numberOfRecentPeople )
    {
        // deletion failed.. just reload the tableview.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
        
        return;
    }
    
    if( [self.peopleFavorites count] == 0 )
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //  need to delete both "clear recent" and "recently viewed" sections
            [self.tableView reloadData];
            
            [self.tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
        }];
    }
    else
    {
        // deletition of a row. Visually performs better with a tableView deleteRows api vs reloadData.
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
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
    if ([segue.identifier isEqualToString:@"showPerson"])
    {
        UITableViewCell *cell = (UITableViewCell *)sender;
        
        if( self.didBeginSearch )
        {
            NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
            PeopleDetailsViewController *vc = (PeopleDetailsViewController *)segue.destinationViewController;
            vc.personDetails = self.searchHandler.searchResults[indexPath.row];
        }
        else
        {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            PeopleDetailsViewController *vc = (PeopleDetailsViewController *)segue.destinationViewController;
            vc.personDetails = self.peopleFavorites[indexPath.row];
        }
    }
}

#pragma mark -

- (void)phoneIconTapped
{
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",MITPeopleDirectoryAssistancePhone]];
	if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
		[[UIApplication sharedApplication] openURL:phoneURL];
    }
}

@end

