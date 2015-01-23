#import "MITPeopleSearchRootViewController.h"
#import "MITPeopleSearchHandler.h"
#import "MITPeopleFavoritesTableViewController.h"
#import "MITPeopleSearchResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "MITLoadingActivityView.h"
#import "MITPeopleSearchSplitContainerViewController.h"
#import "MITPeopleRecentResultsViewController.h"
#import "UIKit+MITAdditions.h"

typedef NS_ENUM(NSUInteger, MITPeopleSearchQueryType) {
    MITPeopleSearchQueryTypeFreeText,
    MITPeopleSearchQueryTypeFavorites,
    MITPeopleSearchQueryTypeRecents
};

@interface MITPeopleSearchRootViewController () <UISearchBarDelegate, MITPeopleFavoritesViewControllerDelegate, MITPeopleSearchViewControllerDelegate, MITPeopleRecentsViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barItem;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) MITPeopleSearchHandler *searchHandler;
@property (nonatomic, assign) BOOL searchBarShouldBeginEditing;
@property (nonatomic, assign) MITPeopleSearchQueryType searchQueryType;

@property (nonatomic, strong) UIPopoverController *favoritesPopover;
@property (nonatomic, strong) UIPopoverController *recentsPopover;

@property (nonatomic, weak) MITPeopleRecentResultsViewController *recentsViewController;

@property (nonatomic, weak) MITPeopleSearchResultsViewController *searchResultsViewController;
@property (nonatomic, weak) PeopleDetailsViewController *searchDetailsViewController;

@end

@implementation MITPeopleSearchRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureNavigationBar];
    [self configureBottomToolbar];
    [self configureChildControllers];
    
    self.searchHandler = [MITPeopleSearchHandler new];
    self.searchBarShouldBeginEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - configs

- (void)configureChildControllers
{
    MITPeopleSearchSplitContainerViewController *splitContainer = [self childViewControllers][0];
    
    UINavigationController *navController = splitContainer.childViewControllers[0];
    self.searchResultsViewController = navController.viewControllers[0];
    self.searchResultsViewController.delegate = self;
    
    UINavigationController *navDetailsController = splitContainer.childViewControllers[1];
    self.searchDetailsViewController = navDetailsController.viewControllers[0];
}

- (void)configureNavigationBar
{
    // favorites button
    [self.barItem setTitle:@"Favorites"];
    [self.barItem setTarget:self];
    [self.barItem setAction:@selector(handleFavorites)];
    [self.navigationItem setRightBarButtonItems:@[self.barItem]];
    
    // configure search bar to be in the center of navigaion bar.
    UIView *searchBarWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.navigationController.navigationBar.frame.size.height)];
    searchBarWrapperView.center = self.navigationController.navigationBar.center;
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search MIT People Directory";
    self.searchBar.frame = searchBarWrapperView.bounds;
    self.searchBar.delegate = self;
    [searchBarWrapperView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarWrapperView;
}

- (void)configureBottomToolbar
{
    UIBarButtonItem *emergencyContactsItem = [[UIBarButtonItem alloc] initWithTitle:@"Emergency Contacts" style:UIBarButtonItemStylePlain target:self action:@selector(emergencyContactsButtonTapped:)];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace], emergencyContactsItem] animated:YES];
}

#pragma mark - actions

- (void)emergencyContactsButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"MITEmergencyContactsModalSegue" sender:self];
}

- (void)handleFavorites
{
    if( self.favoritesPopover )
    {
        return;
    }
    
    [self performSegueWithIdentifier:@"MITFavoritesSegue" sender:self];
}

- (void)showRecentSearchTermsInPopover
{
    if( self.recentsViewController == nil )
    {
        self.recentsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"peopleRecentResults"];
        self.recentsViewController.delegate = self;
        self.recentsViewController.searchHandler = self.searchHandler;
    }
    
    if( self.recentsPopover == nil )
    {
        self.recentsPopover = [[UIPopoverController alloc] initWithContentViewController:self.recentsViewController];
        self.recentsPopover.passthroughViews = @[self.searchBar];
        self.recentsPopover.delegate = self;
    }
    
    [self.recentsViewController reloadRecentResultsWithFilterString:self.searchBar.text];
    
    [self.recentsPopover presentPopoverFromRect:self.searchBar.frame inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)didSelectRecentSearchTerm:(NSString *)searchTerm
{
    self.searchBar.text = searchTerm;
    
    [self prepareForSearch];
    
    [self performSearch];
}

#pragma mark - search methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self prepareForSearch];
    
    [self performSearch];
}

- (void)prepareForSearch
{
    self.searchHandler.searchTerms = self.searchBar.text;
    [self.searchHandler addRecentSearchTerm:self.searchBar.text];
    
    [self.searchBar resignFirstResponder];
    [self.recentsPopover dismissPopoverAnimated:YES];
    
    [self setSearchQueryType:MITPeopleSearchQueryTypeFreeText];
}

- (void)performSearch
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    __weak MITPeopleSearchRootViewController *weakSelf = self;
    
    [self.searchHandler performSearchWithCompletionHandler:^(BOOL isSuccess)
     {
         [weakSelf.searchResultsViewController setSearchHandler:self.searchHandler];
         
         if( [self.searchHandler.searchResults count] == 0 )
         {
             weakSelf.searchDetailsViewController.personDetails = nil;
         }
         
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
     }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if( [searchBar isFirstResponder] )
    {
        [self.recentsViewController reloadRecentResultsWithFilterString:searchText];
    }
    
    // TODO: how to differentiate between deleting last char in searchbar and clear all event?
    if ([searchBar.text length] <= 0)
    {
        self.searchHandler.searchResults = nil;
        self.searchHandler.searchTerms = nil;
        self.searchHandler.searchCancelled = YES;
        
        [self.searchResultsViewController setSearchHandler:self.searchHandler];
        self.searchDetailsViewController.personDetails = nil;
        
        // clearing search while keyboard is not visible.. hence we should keep it that way.
        if( ![searchBar isFirstResponder] )
        {
            self.searchBarShouldBeginEditing = NO;
        }
        
        return;
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if( self.searchQueryType == MITPeopleSearchQueryTypeFavorites )
    {
        self.searchBar.text = @"";
        
        [self setSearchQueryType:MITPeopleSearchQueryTypeFreeText];
    }
    
    return [self shouldPerformSearchAction];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self showRecentSearchTermsInPopover];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    BOOL shouldBeginEditing = self.searchBarShouldBeginEditing;
    
    // reset bool property
    self.searchBarShouldBeginEditing = YES;
    
    return shouldBeginEditing && [self shouldPerformSearchAction];
}

#pragma mark - search, recent and favorite delegates

- (void)setSearchQueryType:(MITPeopleSearchQueryType)searchQueryType
{
    UIColor *searchBarTextColor = (searchQueryType == MITPeopleSearchQueryTypeFavorites) ? [UIColor mit_tintColor] : [UIColor blackColor];
    [self.searchBar setSearchTextColor:searchBarTextColor];
    
    _searchQueryType = searchQueryType;
}

- (void)didSelectPerson:(PersonDetails *)person
{    
    self.searchDetailsViewController.personDetails = person;
}

- (void)didSelectFavoritePerson:(PersonDetails *)person
{
    self.searchHandler.searchResults = @[person];
    [self.searchHandler updateSearchTokensForSearchQuery:[person name]];
    
    [self.searchResultsViewController setSearchHandler:self.searchHandler];
    self.searchBar.text = [person name];
    self.searchDetailsViewController.personDetails = person;
    [self setSearchQueryType:MITPeopleSearchQueryTypeFavorites];
    
    [self.searchBar resignFirstResponder];
    
    [self.favoritesPopover dismissPopoverAnimated:YES];
}

- (void)didDismissFavoritesPopover
{
    self.favoritesPopover = nil;
}

- (BOOL)shouldPerformSearchAction
{
    if( [self favoritesPopover] )
    {
        [[self favoritesPopover] dismissPopoverAnimated:YES];
        
        return NO;
    }
    
    return YES;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    [self.searchBar resignFirstResponder];
    
    return YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if( [[segue identifier] isEqualToString:@"MITEmergencyContactsModalSegue"] )
    {
        [segue.destinationViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    else if( [[segue identifier] isEqualToString:@"MITFavoritesSegue"] )
    {
        UINavigationController *navController = [segue destinationViewController];
        MITPeopleFavoritesTableViewController *favoritesTableViewController = [[navController viewControllers] firstObject];
        favoritesTableViewController.delegate = self;
        
        // keeping a reference to popoverController, so that it can be programmatically dismissed later
        self.favoritesPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
        self.favoritesPopover.passthroughViews = nil;
    }
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;  // show both view controllers in all orientations
}

@end
