#import "MITLibrariesSearchResultsViewController.h"
#import "MITLibrariesSearchController.h"

@interface MITLibrariesSearchResultsViewController ()

@end

@implementation MITLibrariesSearchResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewsForCurrentState];
}

- (void)setState:(MITLibrariesSearchResultsViewControllerState)state
{
    if (_state == state) {
        return;
    }
    
    _state = state;
    [self updateViewsForCurrentState];
}

- (void)updateViewsForCurrentState
{
    switch (self.state) {
        case MITLibrariesSearchResultsViewControllerStateLoading: {
            [self showLoadingView];
            break;
        }
        case MITLibrariesSearchResultsViewControllerStateError: {
            [self showErrorView];
            break;
        }
        case MITLibrariesSearchResultsViewControllerStateResults: {
            if (self.searchController.results.count < 1) {
                [self showNoResultsView];
            } else {
                [self showResultsView];
            }
            break;
        }
    }
}

- (void)showLoadingView
{
    // Should be overridden by subclasses
}

- (void)showErrorView
{
    // Should be overridden by subclasses
}

- (void)showNoResultsView
{
    // Should be overridden by subclasses
}

- (void)showResultsView
{
    // Should be overridden by subclasses
}

- (MITLibrariesSearchController *)searchController
{
    if (!_searchController)
    {
        _searchController = [[MITLibrariesSearchController alloc] init];
    }
    return _searchController;
}

- (void)search:(NSString *)searchTerm
{
    self.state = MITLibrariesSearchResultsViewControllerStateLoading;
    
    [self.searchController search:searchTerm completion:^(NSError *error) {
        [self searchFinishedLoadingWithError:error];
    }];
}

- (void)searchFinishedLoadingWithError:(NSError *)error
{
    if (error) {
        self.state = MITLibrariesSearchResultsViewControllerStateError;
    } else {
        self.state = MITLibrariesSearchResultsViewControllerStateResults;
        [self reloadResultsView];
    }
}

- (void)reloadResultsView
{
    // Should be overridden by subclasses
}

@end
