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
#import "MITTelephoneHandler.h"

typedef NS_ENUM(NSInteger, MITPeopleSearchTableViewSection) {
    MITPeopleSearchTableViewSectionExample = 0,
    MITPeopleSearchTableViewSectionContacts = 1,
    MITPeopleSearchTableViewSectionFavorites = 2
};

// Hard-code this for now, should be pulled from the API in the future
static NSString* const MITPeopleDirectoryAssistancePhone = @"617.253.1000";

@interface PeopleSearchViewController () <UISearchBarDelegate, UIAlertViewDelegate, MITPeopleRecentsViewControllerDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.searchHandler = [MITPeopleSearchHandler new];
    
    [self configureRecentResultsController];
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.searchBar.delegate = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    self.strongSearchDisplayController = searchController;

    self.tableView.tableHeaderView = searchController.searchBar;
    self.searchBar = searchController.searchBar;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    self.peopleFavorites = [PeopleFavoriteData retrieveFavoritePeople];
    
    if (!self.didBeginSearch)
    {
        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
        if (selectedRow && self.clearsSelectionOnViewWillAppear)
        {
            [self.tableView deselectRowAtIndexPath:selectedRow animated:animated];
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
         [weakSelf.tableView reloadData];
         [weakSelf.searchResultsLoadingView removeFromSuperview];
     }];
    
    [self showLoadingView];
}

- (NSArray *)searchResults
{
    return self.searchHandler.searchResults;
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    self.didBeginSearch = YES;
    
    [self setRecentResultsHidden:NO];
    
    if (self.searchHandler.searchTerms)
    {
        searchController.searchBar.text = self.searchHandler.searchTerms;
        [self performSearch];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    [self setRecentResultsHidden:YES];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.searchHandler.searchTerms = nil;
    self.searchHandler.searchTokens = nil;
    self.searchHandler.searchResults = nil;
    [self.searchResultsLoadingView removeFromSuperview];
    
    self.didBeginSearch = NO;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self.recentResultsVC reloadRecentResultsWithFilterString:searchController.searchBar.text];
    
    if ([searchController.searchBar.text length] <= 0) {
        self.searchHandler.searchResults = nil;
        self.searchHandler.searchTerms = nil;
        self.searchHandler.searchCancelled = YES;
        [self.tableView reloadData];
        
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
    
    [self.tableView reloadData];
}


- (void)beginExternalSearch:(NSString *)externalSearchTerms {
	self.searchHandler.searchTerms = externalSearchTerms;

    if (self.didBeginSearch) {
        self.strongSearchDisplayController.searchBar.text = externalSearchTerms;
        [self.strongSearchDisplayController.searchBar resignFirstResponder];
        [self performSearch];
    } else {
        [self.strongSearchDisplayController setActive:YES];
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
    if (!self.didBeginSearch) {
        return 3;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.didBeginSearch)
    {
        return [self numberOfRowsInDefaultScreenSection:section];
	}
    else
    {
        return [self.searchHandler.searchResults count];
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
    if (!self.didBeginSearch)
    {
        // show phone directory tel #, recents
        return [self tableView:self.tableView cellForDefaultRowAtIndexPath:indexPath];
	}
    else
    {
        return [self tableView:self.tableView cellForSearchRowAtIndexPath:indexPath];
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
            cell.detailTextLabel.text = nil;
            for (NSString *tag in @[@"title", @"dept"]) {
                NSString *displayText = [favorite valueForKey:tag];
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
    if (!self.didBeginSearch) {
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
    else
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
    if (!self.didBeginSearch) {
        if (MITPeopleSearchTableViewSectionFavorites == section) {
            return [self.peopleFavorites count] > 0 ? @"Favorites" : @" ";
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.didBeginSearch)
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
    else
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
    if (self.didBeginSearch) {
        MITLoadingActivityView *loadingView = self.searchResultsLoadingView;
        if (!self.searchResultsLoadingView) {
            CGRect frame = self.tableView.bounds;
            loadingView = [[MITLoadingActivityView alloc] initWithFrame:frame];

            self.searchResultsLoadingView = loadingView;
        }

        [self.tableView addSubview:loadingView];
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
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
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
    [MITTelephoneHandler attemptToCallPhoneNumber:MITPeopleDirectoryAssistancePhone];
}

@end

