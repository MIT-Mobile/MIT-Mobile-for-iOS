#import "MITLibrariesHomeViewControllerPad.h"
#import "MITLibrariesYourAccountViewControllerPad.h"
#import "MITLibrariesLocationsHoursViewController.h"
#import "MITLibrariesLibraryDetailViewController.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesQuickLinksViewController.h"
#import "MITLibrariesRecentSearchesViewController.h"
#import "MITLibrariesSearchResultsContainerViewControllerPad.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesAskUsHomeViewController.h"
#import "MITLibrariesAskUsFormSheetViewController.h"
#import "MITLibrariesConsultationFormSheetViewController.h"
#import "MITLibrariesTellUsFormSheetViewController.h"
#import "MITLibrariesSearchResultsViewController.h"

typedef NS_ENUM(NSInteger, MITLibrariesPadDisplayMode) {
    MITLibrariesPadDisplayModeAccount,
    MITLibrariesPadDisplayModeSearch
};

static CGSize const MITLibrariesHomeViewControllerPadFormSheetPresentationPreferredContentSize = {480,400};

@interface MITLibrariesHomeViewControllerPad () <MITLibrariesLocationsIPadDelegate, UISearchBarDelegate, MITLibrariesRecentSearchesDelegate, MITLibrariesAskUsHomeViewControllerDelegate, MITLibrariesSearchResultsViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) MITLibrariesYourAccountViewControllerPad *accountViewController;
@property (nonatomic, strong) MITLibrariesSearchResultsContainerViewControllerPad *searchViewController;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *cancelSearchButton;

@property (nonatomic, strong) UIBarButtonItem *locationsAndHoursButton;
@property (nonatomic, strong) UIBarButtonItem *askUsTellUsButton;
@property (nonatomic, strong) UIBarButtonItem *quickLinksButton;

@property (nonatomic, strong) NSArray *links;

@property (nonatomic, strong) UIPopoverController *locationsAndHoursPopoverController;
@property (nonatomic, strong) UIPopoverController *quickLinksPopoverController;
@property (nonatomic, strong) UIPopoverController *recentSearchesPopoverController;
@property (nonatomic, strong) UIPopoverController *askUsHomePopoverController;

@property (nonatomic, strong) MITLibrariesQuickLinksViewController *quickLinksViewController;
@property (nonatomic, strong) MITLibrariesRecentSearchesViewController *recentSearchesViewController;

@property (nonatomic) MITLibrariesLayoutMode layoutMode;
@property (nonatomic, strong) UIBarButtonItem *gridLayoutButton;
@property (nonatomic, strong) UIBarButtonItem *listLayoutButton;

@property (nonatomic) MITLibrariesPadDisplayMode displayMode;
@property (nonatomic, strong) NSLayoutConstraint *cancelSearchButtonWidthConstraint;

@end

@implementation MITLibrariesHomeViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupNavBar];
    
    [self setupViewControllers];

    [self setupToolbar];

    [self loadLinks];
}

#pragma mark - View Setup

- (void)setupNavBar
{
    [self setupSearchBar];
    
    self.listLayoutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"libraries/list-view"] style:UIBarButtonItemStylePlain target:self action:@selector(listViewPressed)];
    self.gridLayoutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"libraries/grid-view"] style:UIBarButtonItemStylePlain target:self action:@selector(gridViewPressed)];
    self.layoutMode = MITLibrariesLayoutModeList;
}

- (void)setupSearchBar
{
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.placeholder = @"Search MIT's WorldCat";
    self.searchBar.delegate = self;

    self.cancelSearchButton = [[UIButton alloc] init];
    [self.cancelSearchButton setTitle:@"" forState:UIControlStateNormal];
    [self.cancelSearchButton setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
    self.cancelSearchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelSearchButton addTarget:self action:@selector(searchBarCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelSearchButton.enabled = NO;
    
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];

    [searchBarView addSubview:self.searchBar];
    [searchBarView addSubview:self.cancelSearchButton];
    
    self.navigationItem.titleView = searchBarView;
    
    [self setupSearchBarConstraintsWithSearchBarView:searchBarView];
}

- (void)setupSearchBarConstraintsWithSearchBarView:(UIView *)searchBarView
{
    NSLayoutConstraint *searchBarTop = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.searchBar
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0.0];
    NSLayoutConstraint *searchBarLeft = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                     attribute:NSLayoutAttributeLeft
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.searchBar
                                                                     attribute:NSLayoutAttributeLeft
                                                                    multiplier:1.0
                                                                      constant:0.0];
    NSLayoutConstraint *searchBarBottom = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.searchBar
                                                                       attribute:NSLayoutAttributeBottom
                                                                      multiplier:1.0
                                                                        constant:0.0];
    NSLayoutConstraint *searchBarRight = [NSLayoutConstraint constraintWithItem:self.searchBar
                                                                      attribute:NSLayoutAttributeRight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.cancelSearchButton
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0.0];
    
    NSLayoutConstraint *cancelTop = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.cancelSearchButton
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant:0.0];
    NSLayoutConstraint *cancelRight = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.cancelSearchButton
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:0.0];
    NSLayoutConstraint *cancelBottom = [NSLayoutConstraint constraintWithItem:searchBarView
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.cancelSearchButton
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0];
    self.cancelSearchButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:self.cancelSearchButton
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:0];
    
    [searchBarView addConstraints:@[searchBarTop, searchBarLeft, searchBarBottom, searchBarRight, cancelTop, cancelRight, cancelBottom, self.cancelSearchButtonWidthConstraint]];
}

- (void)setupViewControllers
{
    [self setupYourAccountViewController];
    [self setupSearchResultsViewController];
    [self setupRecentSearchesViewController];
    [self setupQuickLinksPopover];
    self.displayMode = MITLibrariesPadDisplayModeAccount;
}

- (void)setupYourAccountViewController
{
    self.accountViewController = [[MITLibrariesYourAccountViewControllerPad alloc] init];
    self.accountViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.accountViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.accountViewController];
    
    [self.view addSubview:self.accountViewController.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
}

- (void)setupSearchResultsViewController
{
    self.searchViewController = [[MITLibrariesSearchResultsContainerViewControllerPad alloc] init];
    self.searchViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchViewController.view.frame = self.view.bounds;
    self.searchViewController.delegate = self;
    
    [self addChildViewController:self.searchViewController];
    
    [self.view addSubview:self.searchViewController.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[searchView]-0-|" options:0 metrics:nil views:@{@"searchView": self.searchViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[searchView]-0-|" options:0 metrics:nil views:@{@"searchView": self.searchViewController.view}]];
}

- (void)setupQuickLinksPopover
{
    self.quickLinksViewController = [[MITLibrariesQuickLinksViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.quickLinksViewController];
    
    self.quickLinksPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.quickLinksPopoverController setPopoverContentSize:CGSizeMake(320, 132 + navController.navigationBar.frame.size.height)];
}

- (void)setupRecentSearchesViewController
{
    self.recentSearchesViewController = [[MITLibrariesRecentSearchesViewController alloc] init];
    self.recentSearchesViewController.delegate = self;
    UINavigationController *navContainer = [[UINavigationController alloc] initWithRootViewController:self.recentSearchesViewController];
    self.recentSearchesPopoverController = [[UIPopoverController alloc] initWithContentViewController:navContainer];
    self.recentSearchesPopoverController.passthroughViews = @[self.cancelSearchButton];
    self.recentSearchesPopoverController.delegate = self;
}

- (void)setupToolbar
{
    self.navigationController.toolbar.translucent = NO;
    self.locationsAndHoursButton = [[UIBarButtonItem alloc] initWithTitle:@"Locations & Hours" style:UIBarButtonItemStylePlain target:self action:@selector(locationsAndHoursPressed:)];
    self.askUsTellUsButton = [[UIBarButtonItem alloc] initWithTitle:@"Ask Us/Tell Us" style:UIBarButtonItemStylePlain target:self action:@selector(askUsTellUsPressed:)];
    self.quickLinksButton = [[UIBarButtonItem alloc] initWithTitle:@"Quick Links" style:UIBarButtonItemStylePlain target:self action:@selector(quickLinksPressed:)];
    
    CGSize locationsSize = [self.locationsAndHoursButton.title sizeWithAttributes:[self.locationsAndHoursButton titleTextAttributesForState:UIControlStateNormal]];
    CGSize quickLinksSize = [self.quickLinksButton.title sizeWithAttributes:[self.quickLinksButton titleTextAttributesForState:UIControlStateNormal]];
    
    UIBarButtonItem *evenPaddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    evenPaddingButton.width = locationsSize.width - quickLinksSize.width;
    
    self.toolbarItems = @[self.locationsAndHoursButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.askUsTellUsButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          evenPaddingButton,
                          self.quickLinksButton];
    [self.navigationController setToolbarHidden:NO];
}

#pragma mark - Toolbar Button Presses

- (void)locationsAndHoursPressed:(id)sender
{
    MITLibrariesLocationsHoursViewController *vc = [[MITLibrariesLocationsHoursViewController alloc] init];
    vc.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.locationsAndHoursPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.locationsAndHoursPopoverController setPopoverContentSize:CGSizeMake(320, 568)];
    [self.locationsAndHoursPopoverController presentPopoverFromBarButtonItem:self.locationsAndHoursButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)askUsTellUsPressed:(id)sender
{
    MITLibrariesAskUsHomeViewController *askUsHomeVC = [MITLibrariesAskUsHomeViewController new];
    NSArray *topGroup = @[@(MITLibrariesAskUsOptionAskUs), @(MITLibrariesAskUsOptionConsultation), @(MITLibrariesAskUsOptionTellUs)];
    NSArray *bottomGroup = @[@(MITLibrariesAskUsOptionGeneral)];
    askUsHomeVC.availableAskUsOptions = @[topGroup, bottomGroup];
    askUsHomeVC.delegate = self;
    UINavigationController *askUsNav = [[UINavigationController alloc] initWithRootViewController:askUsHomeVC];
    self.askUsHomePopoverController = [[UIPopoverController alloc] initWithContentViewController:askUsNav];
    self.askUsHomePopoverController.popoverContentSize = CGSizeMake(320, 400);
    [self.askUsHomePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)quickLinksPressed:(id)sender
{
    [self.quickLinksPopoverController presentPopoverFromBarButtonItem:self.quickLinksButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark - Links

- (void)loadLinks
{
    [MITLibrariesWebservices getLinksWithCompletion:^(NSArray *links, NSError *error) {
        if (links) {
            self.links = links;
        }
    }];
}

- (void)setLinks:(NSArray *)links
{
    _links = links;
    if (self.quickLinksViewController) {
        self.quickLinksViewController.links = links;
    }
}

#pragma mark - Layout/Display Modes

- (void)setLayoutMode:(MITLibrariesLayoutMode)layoutMode
{
    _layoutMode = layoutMode;
    
    if (layoutMode == MITLibrariesLayoutModeList) {
        self.navigationItem.rightBarButtonItem = self.gridLayoutButton;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.listLayoutButton;
    }
    
    self.searchViewController.layoutMode = layoutMode;
    self.accountViewController.layoutMode = layoutMode;
}

- (void)listViewPressed
{
    self.layoutMode = MITLibrariesLayoutModeList;
}

- (void)gridViewPressed
{
    self.layoutMode = MITLibrariesLayoutModeGrid;
}

- (void)setDisplayMode:(MITLibrariesPadDisplayMode)displayMode
{
    _displayMode = displayMode;
    if (displayMode == MITLibrariesPadDisplayModeAccount) {
        self.searchViewController.view.hidden = YES;
        self.accountViewController.view.hidden = NO;
    }
    else {
        self.accountViewController.view.hidden = YES;
        self.searchViewController.view.hidden = NO;
    }
}

#pragma mark - MITLibrariesLocationsIPadDelegate

- (void)showLibraryDetailForLibrary:(MITLibrariesLibrary *)library
{
    MITLibrariesLibraryDetailViewController *detailVC = [[MITLibrariesLibraryDetailViewController alloc] init];
    detailVC.library = library;
    detailVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:detailVC action:@selector(dismiss)];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.locationsAndHoursPopoverController dismissPopoverAnimated:YES];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.cancelSearchButton.enabled = YES;
    [self.cancelSearchButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancelSearchButtonWidthConstraint.constant = 60;
    self.displayMode = MITLibrariesPadDisplayModeSearch;
    [self.recentSearchesPopoverController presentPopoverFromRect:CGRectMake(self.navigationItem.titleView.bounds.size.width / 2, self.navigationItem.titleView.bounds.size.height, 1, 1) inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)searchBarCancelPressed:(UIButton *)sender
{
    [self.recentSearchesPopoverController dismissPopoverAnimated:YES];
    
    self.cancelSearchButton.enabled = YES;
    self.cancelSearchButtonWidthConstraint.constant = 0;
    [self.cancelSearchButton setTitle:@"" forState:UIControlStateNormal];

    self.searchBar.text = nil;
    [self.searchBar resignFirstResponder];
    self.displayMode = MITLibrariesPadDisplayModeAccount;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.recentSearchesPopoverController dismissPopoverAnimated:YES];
    
    NSString *searchTerm = searchBar.text;
    [self.searchViewController search:searchTerm];
}

- (void)recentSearchesDidSelectSearchTerm:(NSString *)searchTerm
{
    self.searchBar.text = searchTerm;
    [self searchBarSearchButtonClicked:self.searchBar];
}

#pragma mark - MITLibrariesAskUsHomeViewControllerDelegate

- (void)librariesAskUsHomeViewController:(MITLibrariesAskUsHomeViewController *)askUsHomeViewController didSelectAskUsOption:(MITLibrariesAskUsOption)selectedOption
{
    [self.askUsHomePopoverController dismissPopoverAnimated:YES];
    
    UIViewController *formSheetVCForPresentation;
    switch (selectedOption) {
        case MITLibrariesAskUsOptionAskUs: {
            formSheetVCForPresentation = [MITLibrariesAskUsFormSheetViewController new];
            break;
        }
        case MITLibrariesAskUsOptionConsultation: {
            formSheetVCForPresentation = [MITLibrariesConsultationFormSheetViewController new];
            break;
        }
        case MITLibrariesAskUsOptionTellUs: {
            formSheetVCForPresentation = [MITLibrariesTellUsFormSheetViewController new];
            break;
        }
        case MITLibrariesAskUsOptionGeneral: {
            NSURL *url = [NSURL URLWithString:@"tel://16173242275"];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        }
        default:
            break;
    }
    
    if (formSheetVCForPresentation) {
        formSheetVCForPresentation.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(presentedFormSheetViewControllerCancelButtonPressed:)];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:formSheetVCForPresentation];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.preferredContentSize = MITLibrariesHomeViewControllerPadFormSheetPresentationPreferredContentSize;
        [self presentViewController:nav animated:NO completion:nil];
    }
}

- (void)presentedFormSheetViewControllerCancelButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MITLibrariesSearchResultsViewControllerDelegate

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.recentSearchesPopoverController) {
        [self.searchBar resignFirstResponder];
    }
}

@end
