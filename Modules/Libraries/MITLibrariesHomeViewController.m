#import "MITLibrariesHomeViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesLink.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"
#import "MITLibrariesSearchResultsListViewController.h"
#import "MITLibrariesLocationsHoursViewController.h"
#import "MITLibrariesSearchResultDetailViewController.h"
#import "MITLibrariesYourAccountViewController.h"
#import "MITLibrariesAskUsHomeViewController.h"

static NSInteger const kMITLibrariesHomeViewControllerNumberOfSections = 2;

static NSInteger const kMITLibrariesHomeViewControllerMainSection = 0;
static NSInteger const kMITLibrariesHomeViewControllerLinksSection = 1;

static NSInteger const kMITLibrariesHomeViewControllerMainSectionCount = 4;
static NSInteger const kMITLibrariesHomeViewControllerMainSectionYourAccountRow = 0;
static NSInteger const kMITLibrariesHomeViewControllerMainSectionLocationHoursRow = 1;
static NSInteger const kMITLibrariesHomeViewControllerMainSectionAskUsRow = 2;
static NSInteger const kMITLibrariesHomeViewControllerMainSectionTellUsRow = 3;

typedef NS_ENUM(NSInteger, MITLibrariesHomeViewControllerLinksStatus) {
    MITLibrariesHomeViewControllerLinksStatusLoaded,
    MITLibrariesHomeViewControllerLinksStatusLoading,
    MITLibrariesHomeViewControllerLinksStatusFailed
};

static NSString * const kMITLibrariesHomeViewControllerDefaultCellIdentifier = @"kMITLibrariesHomeViewControllerDefaultCellIdentifier";

@interface MITLibrariesHomeViewController () <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, MITLibrariesSearchResultsViewControllerDelegate>

@property (nonatomic, strong) NSArray *links;
@property (nonatomic, assign) MITLibrariesHomeViewControllerLinksStatus linksStatus;
@property (nonatomic, assign) BOOL inSearchMode;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UIView *searchContainerView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSLayoutConstraint *cancelButtonTrailingSpaceConstraint;
@property (nonatomic, weak) IBOutlet UIView *preSearchOverlay;
@property (nonatomic, strong) MITLibrariesSearchResultsListViewController *searchResultsViewController;
@property (nonatomic, strong) IBOutlet UITableView *mainTableView;

@end

@implementation MITLibrariesHomeViewController


#pragma mark - Init/Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Libraries";
    self.view.backgroundColor = [UIColor librariesBackgroundColor];
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.navigationBar.barTintColor = [UIColor librariesBackgroundColor];
    
    self.inSearchMode = NO;
    
    [self setupSearchBar];
    [self setupCancelButton];
    [self setupSearchContainer];
    [self setupSearchResultsViewController];
    [self registerCells];

    [self loadLinks];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.inSearchMode) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}

- (void)registerCells
{
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITLibrariesHomeViewControllerDefaultCellIdentifier];
}

- (void)setupSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.searchContainerView.bounds];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search MIT's WorldCat";
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchContainerView addSubview:self.searchBar];
}

- (void)setupCancelButton
{
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont librariesTitleStyleFont];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.frame = CGRectMake(self.searchContainerView.bounds.size.width + 67, 0, 67, self.searchContainerView.bounds.size.height);
    [self.searchContainerView addSubview:self.cancelButton];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addConstraint:[NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:67]];
}

- (void)setupSearchContainer
{
    self.searchContainerView.backgroundColor = [UIColor librariesBackgroundColor];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-0-[searchContainerView]" options:0 metrics:nil views:@{@"topLayoutGuide": self.topLayoutGuide, @"searchContainerView": self.searchContainerView}]];
    [self setupSearchContainerConstraints];
}

- (void)setupSearchContainerConstraints
{
    [self.searchContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[searchBar]-0-[cancelButton]" options:0 metrics:nil views:@{@"searchBar": self.searchBar, @"cancelButton": self.cancelButton}]];
    [self.searchContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[searchBar]-0-|" options:0 metrics:nil views:@{@"searchBar": self.searchBar}]];
    [self.searchContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cancelButton]-0-|" options:0 metrics:nil views:@{@"cancelButton": self.cancelButton}]];
    
    self.cancelButtonTrailingSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.searchContainerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.cancelButton attribute:NSLayoutAttributeTrailing multiplier:1 constant:-self.cancelButton.bounds.size.width];
    [self.searchContainerView addConstraint:self.cancelButtonTrailingSpaceConstraint];
}

- (void)setupSearchResultsViewController
{
    self.searchResultsViewController = [[MITLibrariesSearchResultsListViewController alloc] initWithNibName:nil bundle:nil];
    self.searchResultsViewController.delegate = self;
    [self addChildViewController:self.searchResultsViewController];
    self.searchResultsViewController.view.hidden = YES;
    [self.view addSubview:self.searchResultsViewController.view];
    self.searchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchResultsViewController didMoveToParentViewController:self];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[searchResultsView]-0-|" options:0 metrics:nil views:@{@"searchResultsView": self.searchResultsViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[searchBar]-0-[searchResultsView]-0-|" options:0 metrics:nil views:@{@"searchResultsView": self.searchResultsViewController.view,
                                                                                                                                                       @"searchBar": self.searchBar}]];
}

- (void)loadLinks
{
    self.linksStatus = MITLibrariesHomeViewControllerLinksStatusLoading;
    [MITLibrariesWebservices getLinksWithCompletion:^(NSArray *links, NSError *error) {
        if (links) {
            self.links = links;
            self.linksStatus = MITLibrariesHomeViewControllerLinksStatusLoaded;            
        } else {
            self.links = nil;
            self.linksStatus = MITLibrariesHomeViewControllerLinksStatusFailed;
        }
        [self.mainTableView reloadData];
    }];
}

#pragma mark - TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kMITLibrariesHomeViewControllerNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITLibrariesHomeViewControllerMainSection: {
            return kMITLibrariesHomeViewControllerMainSectionCount;
            break;
        }
        case kMITLibrariesHomeViewControllerLinksSection: {
            if (self.linksStatus == MITLibrariesHomeViewControllerLinksStatusLoaded) {
                return self.links.count;
            } else {
                return 1;
            }
            break;
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITLibrariesHomeViewControllerMainSection: {
            return [self cellForMainSectionAtRow:indexPath.row];
            break;
        }
        case kMITLibrariesHomeViewControllerLinksSection: {
            return [self cellForLinksSectionAtRow:indexPath.row];
            break;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case kMITLibrariesHomeViewControllerMainSection: {
            [self mainSectionCellSelectedAtRow:indexPath.row];
            break;
        }
        case kMITLibrariesHomeViewControllerLinksSection: {
            [self linksSectionCellSelectedAtRow:indexPath.row];
            break;
        }
    }
}

#pragma mark - Custom Cell Creation

- (UITableViewCell *)cellForMainSectionAtRow:(NSInteger)row
{
    UITableViewCell *cell = [self.mainTableView dequeueReusableCellWithIdentifier:kMITLibrariesHomeViewControllerDefaultCellIdentifier];
    
    switch (row) {
        case kMITLibrariesHomeViewControllerMainSectionYourAccountRow: {
            cell.textLabel.text = @"Your Account";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionLocationHoursRow: {
            cell.textLabel.text = @"Locations & Hours";
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionAskUsRow: {
            cell.textLabel.text = @"Ask Us!";
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionTellUsRow: {
            cell.textLabel.text = @"Tell Us!";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            break;
        }
        default: {
            cell.textLabel.text = nil;
            cell.accessoryType = nil;
            cell.accessoryView = nil;
        }
    }
    
    return cell;
}

- (UITableViewCell *)cellForLinksSectionAtRow:(NSInteger)row
{
    UITableViewCell *cell = [self.mainTableView dequeueReusableCellWithIdentifier:kMITLibrariesHomeViewControllerDefaultCellIdentifier];
    
    switch (self.linksStatus) {
        case MITLibrariesHomeViewControllerLinksStatusLoaded: {
            if (row < self.links.count) {
                MITLibrariesLink *link = self.links[row];
                cell.textLabel.text = link.title;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            } else {
                cell.textLabel.text = nil;
                cell.accessoryView = nil;
            }
            break;
        }
        case MITLibrariesHomeViewControllerLinksStatusLoading: {
            cell.textLabel.text = @"Loading...";
            cell.accessoryView = nil;
            break;
        }
        case MITLibrariesHomeViewControllerLinksStatusFailed: {
            cell.textLabel.text = @"Could not load links.";
            cell.accessoryView = nil;
            break;
        }
    }
    
    return cell;
}

#pragma mark - Custom Cell Selection Handling

- (void)mainSectionCellSelectedAtRow:(NSInteger)row
{
    switch (row) {
        case kMITLibrariesHomeViewControllerMainSectionYourAccountRow: {
            MITLibrariesYourAccountViewController *accountVC = [[MITLibrariesYourAccountViewController alloc] init];
            [self.navigationController pushViewController:accountVC animated:YES];
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionLocationHoursRow: {
            {
                MITLibrariesLocationsHoursViewController *locationsVC = [[MITLibrariesLocationsHoursViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:locationsVC animated:YES];
            }
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionAskUsRow: {
            MITLibrariesAskUsHomeViewController *askUsHomeVC = [MITLibrariesAskUsHomeViewController new];
            [self.navigationController pushViewController:askUsHomeVC animated:YES];
            break;
        }
        case kMITLibrariesHomeViewControllerMainSectionTellUsRow: {
            // TODO: Go to "Tell Us" VC
            break;
        }
    }
}

- (void)linksSectionCellSelectedAtRow:(NSInteger)row
{
    if (self.linksStatus == MITLibrariesHomeViewControllerLinksStatusLoaded && row < self.links.count) {
        MITLibrariesLink *link = self.links[row];
        NSURL *linkURL = [NSURL URLWithString:link.url];
        
        if ([[UIApplication sharedApplication] canOpenURL:linkURL]) {
            [[UIApplication sharedApplication] openURL:linkURL];
        }
    }
}

#pragma mark - UISearchBarDelegate Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    self.inSearchMode = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.preSearchOverlay.hidden = NO;
    
    [self setShowingCancelButton:YES animated:YES];
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchResultsViewController search:searchBar.text];
    self.searchResultsViewController.view.hidden = NO;
    self.mainTableView.scrollsToTop = NO;
    
    [self.searchBar resignFirstResponder];
}

#pragma mark - Other SearchBar Methods

- (void)cancelButtonPressed
{
    [self.searchBar endEditing:YES];
    
    self.searchBar.text = nil;
    self.inSearchMode = NO;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.searchBar.searchBarStyle = UISearchBarStyleDefault;
    self.preSearchOverlay.hidden = YES;
    self.searchResultsViewController.view.hidden = YES;
    self.mainTableView.scrollsToTop = YES;
    
    [self setShowingCancelButton:NO animated:YES];
}

- (void)setShowingCancelButton:(BOOL)showCancelButton animated:(BOOL)animated
{
    self.cancelButtonTrailingSpaceConstraint.constant = showCancelButton ? 0 : -self.cancelButton.bounds.size.width;
    [self.searchContainerView setNeedsUpdateConstraints];
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.searchContainerView layoutIfNeeded];
        }];
    } else {
        [self.searchContainerView layoutIfNeeded];
    }
}

#pragma mark - MITLibrariesSearchResultsViewControllerDelegate Methods

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    MITLibrariesSearchResultDetailViewController *detailVC = [[MITLibrariesSearchResultDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.worldcatItem = item;
    [detailVC hydrateCurrentItem];
    [self.navigationController pushViewController:detailVC animated:YES];
}

@end