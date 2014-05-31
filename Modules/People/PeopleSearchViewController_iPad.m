//
//  PeopleSearchViewController_iPad.m
//  MIT Mobile
//
//  Created by YevDev on 5/25/14.
//
//

#import "PeopleSearchViewController_iPad.h"
#import "PeopleSearchResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "UIKit+MITAdditions.h"
#import "PeopleSearchHandler.h"

@interface PeopleSearchViewController_iPad () <UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UILabel *sampleSearchesLabel;
@property (nonatomic, weak) IBOutlet UIButton *emergencyContactsButton;
@property (nonatomic, weak) IBOutlet UIView *searchResultsViewContainer;
@property (nonatomic, weak) IBOutlet UIView *searchDetailsViewContainer;

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property PeopleSearchResultsViewController *searchResultsViewController;
@property PeopleDetailsViewController *searchDetailsViewController;

@end

@implementation PeopleSearchViewController_iPad
{
    PeopleSearchHandler *searchHandler;
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
    
    UIBarButtonItem *favItem = [[UIBarButtonItem alloc] initWithTitle:@"Favorites" style:UIBarButtonItemStylePlain target:self action:@selector(handleFavorites)];
    [self.navigationItem setRightBarButtonItems:@[favItem]];

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
    
    searchHandler = [PeopleSearchHandler new];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self configureChildControllers];
}

- (void) configureChildControllers
{
    self.searchResultsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleSearchResultsViewController"];
    self.searchResultsViewController.delegate = self;
    [self addChildViewController:self.searchResultsViewController];
    [self.searchResultsViewContainer addSubview:self.searchResultsViewController.view];
    [self.searchResultsViewController didMoveToParentViewController:self];
    
    self.searchDetailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PeopleSearchDetailsViewController"];
    [self addChildViewController:self.searchDetailsViewController];
    [self.searchDetailsViewContainer addSubview:self.searchDetailsViewController.view];
    [self.searchDetailsViewController didMoveToParentViewController:self];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
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

- (void) handleFavorites
{
    //todo
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
        
        searchBar.showsCancelButton = NO;
        
        //TODO: go back to the main screen
        
        return;
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    searchHandler.searchResults = nil;
    searchHandler.searchTerms = nil;
    searchHandler.searchCancelled = YES;
    searchBar.text = nil;
    searchBar.showsCancelButton = NO;
    
    [searchBar resignFirstResponder];
    
    //TODO: go back to the main screen
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchHandler.searchTerms = searchBar.text;
	[self performSearch];
    
    [self.searchBar resignFirstResponder];
}

- (void)performSearch
{
    [searchHandler performSearchWithCompletionHandler:^(BOOL isSuccess)
     {
         BOOL showSearchResults = [searchHandler.searchResults count] > 0;
         
         if( showSearchResults  )
         {
             [self.searchResultsViewController setSearchHandler:searchHandler];
             [self.searchResultsViewController reload];
         }
         
         [self.searchResultsViewContainer setHidden:!showSearchResults];
         [self.searchDetailsViewContainer setHidden:!showSearchResults];
     }];
}

- (void) didSelectPerson:(PersonDetails *)person
{
    self.searchDetailsViewController.personDetails = person;
    
    [self.searchDetailsViewController reloadDataIfNeeded];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if( [[segue identifier] isEqualToString:@"SearchResultsSegue"] )
    {
        self.searchResultsViewController = segue.destinationViewController;
    }
    else if( [[segue identifier] isEqualToString:@"SearchDetailsSegue"] )
    {
        self.searchDetailsViewController = segue.destinationViewController;
    }
}


@end
