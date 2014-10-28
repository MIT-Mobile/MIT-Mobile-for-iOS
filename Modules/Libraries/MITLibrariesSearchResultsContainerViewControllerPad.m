#import "MITLibrariesSearchResultsContainerViewControllerPad.h"
#import "MITLibrariesSearchController.h"
#import "MITLibrariesSearchResultsListViewController.h"
#import "MITLibrariesSearchResultDetailViewController.h"
#import "MITLibrariesSearchResultsGridViewController.h"

@interface MITLibrariesSearchResultsContainerViewControllerPad () <MITLibrariesSearchResultsViewControllerDelegate>

@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic, strong) MITLibrariesSearchController *searchController;
@property (nonatomic, strong) MITLibrariesSearchResultsListViewController *listViewController;
@property (nonatomic, strong) MITLibrariesSearchResultsGridViewController *gridViewController;

@end

@implementation MITLibrariesSearchResultsContainerViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupSearchController];
    [self setupViewControllers];
}

- (void)setupSearchController
{
    self.searchController = [[MITLibrariesSearchController alloc] init];
}

- (void)setupViewControllers
{
    self.listViewController = [[MITLibrariesSearchResultsListViewController alloc] init];
    self.listViewController.delegate = self;
    self.listViewController.searchController = self.searchController;
    self.listViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.listViewController];
    
    self.gridViewController = [[MITLibrariesSearchResultsGridViewController alloc] init];
    self.gridViewController.delegate = self;
    self.gridViewController.searchController = self.searchController;
    self.gridViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.gridViewController];
    
    switch (self.layoutMode) {
        case MITLibrariesLayoutModeList: {
            self.gridViewController.view.hidden = YES;
            break;
        }
        case MITLibrariesLayoutModeGrid: {
            self.listViewController.view.hidden = YES;
            break;
        }
    }
    
    [self.view addSubview:self.listViewController.view];
    [self.view addSubview:self.gridViewController.view];
}

- (void)search:(NSString *)searchTerm
{
    self.searchTerm = searchTerm;
     
    self.listViewController.state = MITLibrariesSearchResultsViewControllerStateLoading;
    self.gridViewController.state = MITLibrariesSearchResultsViewControllerStateLoading;
    
    [self.searchController search:searchTerm completion:^(NSError *error) {
        [self.listViewController searchFinishedLoadingWithError:error];
        [self.gridViewController searchFinishedLoadingWithError:error];
    }];
}

- (void)setLayoutMode:(MITLibrariesLayoutMode)layoutMode
{
    if (_layoutMode == layoutMode) {
        return;
    }
    
    _layoutMode = layoutMode;
    
    switch (layoutMode) {
        case MITLibrariesLayoutModeList: {
            [self showListViewController];
            break;
        }
        case MITLibrariesLayoutModeGrid: {
            [self showGridViewController];
            break;
        }
    }
}

- (void)showListViewController
{
    self.gridViewController.view.hidden = YES;
    self.listViewController.view.hidden = NO;
}

- (void)showGridViewController
{
    self.listViewController.view.hidden = YES;
    self.gridViewController.view.hidden = NO;
}

#pragma mark - MITLibrariesSearchResultsViewControllerDelegate

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item
{
    MITLibrariesSearchResultDetailViewController *detailVC = [[MITLibrariesSearchResultDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.worldcatItem = item;
    [detailVC hydrateCurrentItem];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:^{}];
}

@end
