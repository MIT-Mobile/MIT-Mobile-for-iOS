//
//  PeopleSearchViewController_iPad.m
//  MIT Mobile
//
//  Created by YevDev on 5/25/14.
//
//

#import "MITPeopleSearchViewController_iPad.h"
#import "MITPeopleSearchResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITPeopleSearchHandler.h"
#import "PeopleRecentsData.h"
#import "PeopleFavoriteData.h"
#import "MITLoadingActivityView.h"
#import "MITPeopleRecentResultsViewController.h"
#import "MITEmergencyContactsTableViewController.h"
#import "MITPeopleFavoritesTableViewController.h"

@interface MITPeopleSearchViewController_iPad () <UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UILabel *sampleSearchesLabel;
@property (nonatomic, weak) IBOutlet UIButton *emergencyContactsButton;
@property (nonatomic, weak) IBOutlet UIView *searchResultsViewContainer;
@property (nonatomic, weak) IBOutlet UIView *searchDetailsViewContainer;
@property (nonatomic, weak) IBOutlet UIView *searchViewsSeparator;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barItem;

@property (nonatomic, strong) UIPopoverController *recentsPickerPopover;
@property (nonatomic, strong) MITPeopleRecentResultsViewController *recentsPicker;

@property (nonatomic, strong) UIPopoverController *favoritesPopover;

@property (nonatomic, strong) MITLoadingActivityView *searchResultsLoadingView;

@property MITPeopleSearchResultsViewController *searchResultsViewController;
@property PeopleDetailsViewController *searchDetailsViewController;

@end

@implementation MITPeopleSearchViewController_iPad
{
    MITPeopleSearchHandler *searchHandler;
}

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
    
//    UIBarButtonItem *favItem = [[UIBarButtonItem alloc] initWithTitle:@"Favorites" style:UIBarButtonItemStylePlain target:self action:@selector(handleFavorites)];
    [self.barItem setTitle:@"Favorites"];
    [self.barItem setTarget:self];
    [self.barItem setAction:@selector(handleFavorites)];
    [self.navigationItem setRightBarButtonItems:@[self.barItem]];

    // configure search bar to be in the center of navigaion bar.
    UIView *searchBarWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.navigationController.navigationBar.frame.size.height)];
    searchBarWrapperView.center = self.navigationController.navigationBar.center;
    self.searchBar.placeholder = @"Search People Directory";
    self.searchBar.frame = searchBarWrapperView.bounds;
    [searchBarWrapperView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarWrapperView;
    
    // configure main screen
    self.sampleSearchesLabel.text = @"Sample searches:\nName: 'william barton rogers', 'rogers'\nEmail: 'wbrogers', 'wbrogers@mit.edu'\nPhone: '6172531000', '31000'";
    [self.emergencyContactsButton setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
    [self.emergencyContactsButton addTarget:self action:@selector(emergencyContactsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // configure bottom toolbar
    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:nil];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:NO];
    
    // configure bottom toolbar
    [self configureBottomToolbar];
    
    searchHandler = [MITPeopleSearchHandler new];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self configureChildControllers];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self cancelSearch];
    
    //TODO: remove child view controllers
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Setup

- (void) configureBottomToolbar
{
    UILabel *directoryAssistanceLabel = [[UILabel alloc] init];
    directoryAssistanceLabel.font = [UIFont systemFontOfSize:16];
    directoryAssistanceLabel.text = @"Directory Assistance 617.253.1000";
    directoryAssistanceLabel.textColor = [UIColor blackColor];
    directoryAssistanceLabel.backgroundColor = [UIColor clearColor];
    [directoryAssistanceLabel sizeToFit];
    
    UIBarButtonItem *directoryAssistanceItem = [[UIBarButtonItem alloc] initWithCustomView:directoryAssistanceLabel];
    UIBarButtonItem *emergencyContactsItem = [[UIBarButtonItem alloc] initWithTitle:@"Emergency Contacts" style:UIBarButtonItemStylePlain target:self action:@selector(emergencyContactsButtonTapped:)];
    [self setToolbarItems:@[directoryAssistanceItem,[UIBarButtonItem flexibleSpace], emergencyContactsItem] animated:YES];
    
    self.navigationController.toolbarHidden = YES;
}

- (void) configureChildControllers
{
    self.searchResultsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleSearchResultsViewController"];
    self.searchResultsViewController.delegate = self;
    [self addChildViewController:self.searchResultsViewController];
    [self.searchResultsViewContainer addSubview:self.searchResultsViewController.view];
    [self.searchResultsViewController didMoveToParentViewController:self];
    
    self.searchDetailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleSearchDetailsViewController"];
    self.searchDetailsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.searchDetailsViewController];
    [self.searchDetailsViewContainer addSubview:self.searchDetailsViewController.view];
    [self.searchDetailsViewController didMoveToParentViewController:self];
    
    UIView *childView = self.searchDetailsViewController.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(childView);
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[childView]|"
                               options:0 metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-[childView]-|"
                               options:0 metrics:nil
                               views:viewsDictionary]];
}

#pragma mark - actions handling

- (void) emergencyContactsButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"MITEmergencyContactsModalSegue" sender:self];
}

- (void) handleFavorites
{    
    [self performSegueWithIdentifier:@"MITFavoritesSegue" sender:self];
}

- (void)showLoadingView
{
    MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
    self.searchResultsLoadingView = loadingView;
    [self.view addSubview:loadingView];
}

- (void) didSelectRecentPerson:(PersonDetails *)person
{
    // remove recents popover && hide the keyboard
    [self dismissRecentsPopover];
    [self.searchBar resignFirstResponder];
    
    // set search results and search bar text with selected recent person
    searchHandler.searchResults = @[person];
    self.searchBar.text = [person name];
    
    // update search results controller
    [self.searchResultsViewController setSearchHandler:searchHandler];
    [self.searchResultsViewController reload];
    [self.searchResultsViewController selectFirstResult];
    
    // update search details controller
    [self didSelectPerson:person];
    
    // make sure search controllers are visible
    [self setSearchResultViewsHidden:NO];
}

- (void) dismissRecentsPopover
{
    [self.recentsPickerPopover dismissPopoverAnimated:YES];
}

- (void) showRecentsPopoverIfNeeded
{
    if( [[[PeopleRecentsData sharedData] recents] count] <= 0 )
    {
        return;
    }
    
    if( !self.recentsPicker )
    {
        self.recentsPicker = [self.storyboard instantiateViewControllerWithIdentifier:@"peopleRecentResults"];
        self.recentsPicker.delegate = self;
    }
    
    if( !self.recentsPickerPopover )
    {
        self.recentsPickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.recentsPicker];
    }
    
    [self.recentsPickerPopover presentPopoverFromRect:self.searchBar.frame inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
    }
    
    return cell;
}

#pragma mark - Search methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchBar.text length] <= 0)
    {
        searchHandler.searchResults = nil;
        searchHandler.searchTerms = nil;
        searchHandler.searchCancelled = YES;
        
        [self showRecentsPopoverIfNeeded];
                
        return;
    }
    
    if( [self.recentsPickerPopover isPopoverVisible] )
    {
        [self dismissRecentsPopover];
    }
    
    searchBar.showsCancelButton = YES;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [self shouldPerformSearchAction];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return [self shouldPerformSearchAction];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    if ([searchBar.text length] <= 0)
    {
        [self showRecentsPopoverIfNeeded];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    if( ![self shouldPerformSearchAction] )
    {
        return;
    }

    [self cancelSearch];
}

- (void) cancelSearch
{
    searchHandler.searchResults = nil;
    searchHandler.searchTerms = nil;
    searchHandler.searchCancelled = YES;
    self.searchBar.text = nil;
    self.searchBar.showsCancelButton = NO;
    
    [self.searchBar resignFirstResponder];
    
    [self setSearchResultViewsHidden:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchHandler.searchTerms = searchBar.text;
	[self performSearch];
    
    [self.searchBar resignFirstResponder];
}

- (void)performSearch
{
    __weak MITPeopleSearchViewController_iPad *weakSelf = self;
    
    [searchHandler performSearchWithCompletionHandler:^(BOOL isSuccess)
     {
         BOOL showSearchResults = [searchHandler.searchResults count] > 0;
         
         if( showSearchResults  )
         {
             [weakSelf.searchResultsViewController setSearchHandler:searchHandler];
             [weakSelf.searchResultsViewController reload];
         }
         
         [weakSelf setSearchResultViewsHidden:!showSearchResults];
         
         [weakSelf.searchResultsLoadingView removeFromSuperview];
     }];
    
    [self showLoadingView];
}

- (void) setSearchResultViewsHidden:(BOOL)hidden
{
    [self.searchResultsViewContainer setHidden:hidden];
    [self.searchDetailsViewContainer setHidden:hidden];
    [self.searchViewsSeparator setHidden:hidden];
    
    [self.searchResultsViewContainer setUserInteractionEnabled:!hidden];
    [self.searchDetailsViewContainer setUserInteractionEnabled:!hidden];
    [self.searchViewsSeparator setUserInteractionEnabled:!hidden];
    
    self.navigationController.toolbarHidden = hidden;
}

#pragma mark - recent and favorite delegates

- (void) didClearRecents
{
    [self dismissRecentsPopover];
}

- (void) didSelectPerson:(PersonDetails *)person
{
    self.searchDetailsViewController.personDetails = person;
    
    [self.searchDetailsViewController reload];
}

- (void) didSelectFavoritePerson:(PersonDetails *)person
{
    [self setSearchResultViewsHidden:NO];
    
    self.searchDetailsViewController.personDetails = person;
    [self.searchDetailsViewController reload];
    
    [self.favoritesPopover dismissPopoverAnimated:YES];
}

- (void) didDismissFavoritesPopover
{
    self.favoritesPopover = nil;
}

- (BOOL) shouldPerformSearchAction
{
    if( [self favoritesPopover] )
    {
        [[self favoritesPopover] dismissPopoverAnimated:YES];
        
        return NO;
    }
    
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


@end
