#import "MITLibrariesSearchResultsViewController.h"
#import "MITLibrariesSearchController.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "SVPullToRefresh.h"
#import "MITLibrariesWorldcatItem.h"

typedef NS_ENUM(NSInteger, MITLibrariesSearchResultsViewControllerState) {
    MITLibrariesSearchResultsViewControllerStateLoading,
    MITLibrariesSearchResultsViewControllerStateError,
    MITLibrariesSearchResultsViewControllerStateResults
};

static NSString * const kMITLibrariesSearchResultsViewControllerItemCellIdentifier = @"kMITLibrariesSearchResultsViewControllerItemCellIdentifier";

@interface MITLibrariesSearchResultsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *resultsTableView;
@property (nonatomic, strong) MITLibrariesSearchController *searchController;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, assign) MITLibrariesSearchResultsViewControllerState state;

@end

@implementation MITLibrariesSearchResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.searchController = [[MITLibrariesSearchController alloc] init];
        self.state = MITLibrariesSearchResultsViewControllerStateLoading;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *librariesItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.resultsTableView registerNib:librariesItemCellNib forCellReuseIdentifier:kMITLibrariesSearchResultsViewControllerItemCellIdentifier];
    
    self.resultsTableView.showsInfiniteScrolling = NO;
    [self.resultsTableView addInfiniteScrollingWithActionHandler:^{
        NSInteger startingResultCount = self.searchController.results.count;
        
        [self.searchController getNextResults:^(NSError *error) {
            [self.resultsTableView.infiniteScrollingView stopAnimating];
            if (error) {
                self.resultsTableView.showsInfiniteScrolling = NO;
            } else {
                NSInteger addedResultCount = self.searchController.results.count - startingResultCount;
                NSMutableArray *newIndexPaths = [NSMutableArray arrayWithCapacity:addedResultCount];
                for (NSInteger i = 0; i < addedResultCount; i++) {
                    [newIndexPaths addObject:[NSIndexPath indexPathForRow:(startingResultCount + i) inSection:0]];
                }
                
                [self.resultsTableView beginUpdates];
                [self.resultsTableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                [self.resultsTableView endUpdates];
                
                self.resultsTableView.showsInfiniteScrolling = self.searchController.hasMoreResults;
            }
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewsForCurrentState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.state == MITLibrariesSearchResultsViewControllerStateResults) {
        [self.resultsTableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)search:(NSString *)searchTerm
{
    self.state = MITLibrariesSearchResultsViewControllerStateLoading;
    
    [self.searchController search:searchTerm completion:^(NSError *error) {
        if (error) {
            self.state = MITLibrariesSearchResultsViewControllerStateError;
        } else if (self.searchController.results.count < 1) {
            [self showNoResultsView];
        } else {
            self.state = MITLibrariesSearchResultsViewControllerStateResults;
            [self.resultsTableView reloadData];
            self.resultsTableView.showsInfiniteScrolling = self.searchController.hasMoreResults;
        }
    }];
}

- (void)showLoadingView
{
    self.messageLabel.text = @"Loading...";
    self.resultsTableView.hidden = YES;
    self.messageLabel.hidden = NO;
    self.resultsTableView.contentOffset = CGPointMake(0, 0);
}

- (void)showErrorView
{
    self.messageLabel.text = @"There was an error loading your search.";
    self.resultsTableView.hidden = YES;
    self.messageLabel.hidden = NO;
}

- (void)showNoResultsView
{
    self.messageLabel.text = @"No results found.";
    self.resultsTableView.hidden = YES;
    self.messageLabel.hidden = NO;
}

- (void)showResultsView
{
    self.messageLabel.hidden = YES;
    self.resultsTableView.hidden = NO;
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
            [self showResultsView];
            break;
        }
    }
}

#pragma mark - TableView Delegate / DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchController.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesWorldcatItemCell *cell = [self.resultsTableView dequeueReusableCellWithIdentifier:kMITLibrariesSearchResultsViewControllerItemCellIdentifier forIndexPath:indexPath];
    
    [cell setItem:self.searchController.results[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(librariesSearchResultsViewController:didSelectItem:)]) {
        MITLibrariesWorldcatItem *item = self.searchController.results[indexPath.row];
        [self.delegate librariesSearchResultsViewController:self didSelectItem:item];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesWorldcatItem *item = self.searchController.results[indexPath.row];
    CGFloat height = [MITLibrariesWorldcatItemCell heightForItem:item tableViewWidth:self.resultsTableView.bounds.size.width];
    return height;
}

@end