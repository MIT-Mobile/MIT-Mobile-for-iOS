#import "MITLibrariesSearchResultsListViewController.h"
#import "MITLibrariesSearchController.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "SVPullToRefresh.h"
#import "MITLibrariesWorldcatItem.h"

static NSString * const kMITLibrariesSearchResultsViewControllerItemCellIdentifier = @"kMITLibrariesSearchResultsViewControllerItemCellIdentifier";

@interface MITLibrariesSearchResultsListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *resultsTableView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;

@end

@implementation MITLibrariesSearchResultsListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.state = MITLibrariesSearchResultsViewControllerStateLoading;
    }
    
    return self;
}

- (void)viewDidLoad
{
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.state == MITLibrariesSearchResultsViewControllerStateResults) {
        [self.resultsTableView reloadData];
    }
}

- (void)reloadResultsView
{
    [self.resultsTableView reloadData];
    self.resultsTableView.showsInfiniteScrolling = self.searchController.hasMoreResults;
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
    
    [cell setContent:self.searchController.results[indexPath.row]];
    
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
    CGFloat height = [MITLibrariesWorldcatItemCell heightForContent:item tableViewWidth:self.resultsTableView.bounds.size.width];
    return height;
}

@end
