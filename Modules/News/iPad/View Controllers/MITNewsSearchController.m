#import "MITNewsSearchController.h"
#import "MITNewsModelController.h"
#import "MITNewsRecentSearchController.h"
#import "MITNewsConstants.h"
#import "MITNewsStory.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStoryViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITLoadingActivityView.h"
#import "MITViewWithCenterTextAndIndicator.h"
#import "MITViewWithCenterText.h"
#import "MITNewsCustomWidthTableViewCell.h"
#import "MITPopoverBackgroundView.h"

@interface MITNewsSearchController (NewsDataSource) <UIPopoverControllerDelegate, MITNewsStoryViewControllerDelegate>

@end

@interface MITNewsSearchController()
@property (nonatomic, strong) MITNewsRecentSearchController *recentSearchController;
@property (nonatomic, strong) UIPopoverController *recentSearchPopoverController;
@property (nonatomic) BOOL unwindFromStoryDetail;
@property (nonatomic) MITNewsDataSource *dataSource;

@property (nonatomic, weak) MITViewWithCenterTextAndIndicator *messageActivityView;
@property (nonatomic, weak) MITViewWithCenterText *messageView;
@property (nonatomic, strong) NSString *errorMessage;

@end

@implementation MITNewsSearchController {
    BOOL _storyUpdateInProgress;
}

@synthesize recentSearchController = _recentSearchController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

#pragma mark - Dynamic Properties
- (MITNewsRecentSearchController *)recentSearchController
{
    if(!_recentSearchController) {
        MITNewsRecentSearchController *recentSearchController = [[MITNewsRecentSearchController alloc] init];
        recentSearchController.searchController = self;
        _recentSearchController = recentSearchController;
    }
    return _recentSearchController;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }
    
    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark - View lifecyle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];

    self.searchTableView.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SearchBar
- (void)searchBarCancelButtonClicked
{
    [self hideSearchField];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self hideSearchRecents];
    if ([searchBar.text isEqualToString:@""]) {
        self.searchTableView.alpha = 0;
        self.view.alpha = .5;
    } else {
        self.searchTableView.alpha = 1;
        self.view.alpha = 1;
    }
    self.messageActivityView.alpha = 1;

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.recentSearchController addRecentSearchItem:searchBar.text];
    [self getResultsForString:searchBar.text];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (self.unwindFromStoryDetail || self.recentSearchController.confirmSheet != nil) {
        self.unwindFromStoryDetail = NO;
        return NO;
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.messageActivityView.alpha = .5;
    if ([searchBar.text isEqualToString:@""]) {
        self.searchTableView.alpha = 0;
    } else {
        self.searchTableView.alpha = .5;
    }
    [self removeNoResultsView];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self showSearchRecents];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""]) {
        self.searchTableView.alpha = 0;
        self.view.alpha = .5;
        [self clearTable];
    } else {
        self.searchTableView.alpha = .5;
        self.view.alpha = 1;
    }
    [self.recentSearchController filterResultsUsingString:searchText];
}

- (void)clearTable
{
    self.dataSource = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.searchTableView reloadData];
    }];
}

#pragma mark - search
- (void)getResultsForString:(NSString *)searchTerm
{
    [self removeNoResultsView];
    [self addLoadingView];
    [self clearTable];
    self.searchBar.text = searchTerm;
    self.dataSource = [MITNewsStoriesDataSource dataSourceForQuery:searchTerm];
    
    __weak MITNewsSearchController *weakSelf = self;
    [self.dataSource refresh:^(NSError *error) {
        MITNewsSearchController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            DDLogWarn(@"failed to refresh data source %@",self.dataSource);
            if (error.code == NSURLErrorNotConnectedToInternet) {
                strongSelf.errorMessage = @"No Internet Connection";
            } else {
                strongSelf.errorMessage = @"Failed...";
            }
            [strongSelf removeLoadingView];
            [strongSelf addNoResultsView];

        } else {
            DDLogVerbose(@"refreshed data source %@",self.dataSource);
            [strongSelf removeLoadingView];
            
            if ([strongSelf.dataSource.objects count] == 0) {
                [strongSelf addNoResultsView];
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [strongSelf.searchTableView reloadData];
            }];
        }
    }];
    [self.searchBar resignFirstResponder];
    [self.recentSearchPopoverController dismissPopoverAnimated:YES];
    [UIView animateWithDuration:0.33
                          delay:0.
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         self.searchTableView.alpha = 1;
                         self.view.alpha = 1;
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)getMoreStories
{
    if ([self.dataSource hasNextPage] && !_storyUpdateInProgress) {
        _storyUpdateInProgress = TRUE;
        __weak MITNewsSearchController *weakSelf = self;
        [self.dataSource nextPage:^(NSError *error) {
            _storyUpdateInProgress = FALSE;
            MITNewsSearchController *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (error) {
                DDLogWarn(@"failed to get more stories from datasource %@",strongSelf.dataSource);
                if (error.code == NSURLErrorNotConnectedToInternet) {
                    strongSelf.errorMessage = @"No Internet Connection";
                } else {
                    strongSelf.errorMessage = @"Failed...";
                }
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^{
                    strongSelf.errorMessage = nil;
                    [strongSelf.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[strongSelf.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
                [strongSelf.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[strongSelf.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            } else {
                strongSelf.errorMessage = nil;
                DDLogVerbose(@"retrieved more stores from datasource %@",strongSelf.dataSource);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [strongSelf.searchTableView reloadData];
                }];
            }
        }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}

#pragma mark - hide/show Recents
- (void)hideSearchRecents
{
    if (self.recentSearchPopoverController != nil) {
        if (self.recentSearchController.confirmSheet == nil) {
            
            [self.recentSearchPopoverController dismissPopoverAnimated:YES];
            self.recentSearchPopoverController = nil;
        }
    }
}

- (void)showSearchRecents
{
    if (self.recentSearchPopoverController) {
        return;
    }
    UIPopoverController *recentSearchPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.recentSearchController];
    
    recentSearchPopoverController.popoverContentSize = CGSizeMake(300, 350);
    recentSearchPopoverController.delegate = self;
    recentSearchPopoverController.passthroughViews = @[self.searchBar];
    recentSearchPopoverController.popoverBackgroundViewClass = [MITPopoverBackgroundView class];
    
    [recentSearchPopoverController presentPopoverFromRect:[self.searchBar bounds] inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    self.recentSearchPopoverController = recentSearchPopoverController;
    
}

- (void)hideSearchField
{
    [self.delegate hideSearchField];
}

#pragma mark - Popover
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    [self.searchBar resignFirstResponder];

    if (self.searchTableView.alpha == 0) {
        [self hideSearchField];
    }
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.recentSearchPopoverController = nil;
}

#pragma mark - TableView
#pragma mark UITableViewDataSource
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    MITNewsCustomWidthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    if (identifier == MITNewsLoadMoreCellIdentifier && self.errorMessage) {
        cell.textLabel.text = self.errorMessage;
    } else if (identifier == MITNewsLoadMoreCellIdentifier && _storyUpdateInProgress) {
        cell.textLabel.text = @"Loading More...";
    } else if (identifier == MITNewsLoadMoreCellIdentifier) {
        cell.textLabel.text = @"Load More...";
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.dataSource.objects count]) {
        if (self.dataSource.hasNextPage) {
            return [self.dataSource.objects count] + 1;
        }
        return [self.dataSource.objects count];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return 75; // Fixed height for the load more cells
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = nil;
    if ([self.dataSource.objects count] > indexPath.row) {
        story = self.dataSource.objects[indexPath.row];
    }
    if (story) {
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            
            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                if (newsStory.coverImage) {
                    identifier = MITNewsStoryExternalCellIdentifier;
                } else {
                    identifier = MITNewsStoryExternalNoImageCellIdentifier;
                }
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
        
        return identifier;
    } else if ([self.dataSource.objects count]) {
        return MITNewsLoadMoreCellIdentifier;
    } else {
        return nil;
    }
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (_storyUpdateInProgress) {
            if (!cell.accessoryView) {
                UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [view startAnimating];
                cell.accessoryView = view;
            }
        } else {
            cell.accessoryView = nil;
        }
    } else {
        MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
        
        if (story && [cell isKindOfClass:[MITNewsStoryCell class]]) {
            MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsStory *contextStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
                storyCell.story = contextStory;
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    if ([identifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (!_storyUpdateInProgress) {
            [self getMoreStories];
        }
    }
        else {
        MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
        if (story) {
            [self performSegueWithIdentifier:@"showStoryDetail" sender:indexPath];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {
            
            NSIndexPath *indexPath = sender;
            
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
            storyDetailViewController.delegate = self;
            MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
                self.unwindFromStoryDetail = YES;
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

#pragma mark MITNewsStoryDetailPagingDelegate
- (void)storyAfterStory:(MITNewsStory *)story completion:(void (^)(MITNewsStory *, NSError *))block
{
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
    if (currentIndex != NSNotFound) {
        
        if (currentIndex + 1 < [self.dataSource.objects count]) {
            if(block) {
                block(self.dataSource.objects[currentIndex +1], nil);
            }
        } else {
            if ([self.dataSource hasNextPage]) {
               __weak MITNewsSearchController *weakSelf = self;
                
                [self.dataSource nextPage:^(NSError *error) {
                    MITNewsSearchController *strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                
                    if (error) {
                        DDLogWarn(@"failed to get more stories from datasource %@",self.dataSource);
                        
                    } else {
                        DDLogVerbose(@"retrieved more stores from datasource %@",self.dataSource);
                        NSInteger currentIndex = [strongSelf.dataSource.objects indexOfObject:currentStory];
                        
                        if (currentIndex + 1 < [strongSelf.dataSource.objects count]) {
                            if(block) {
                                block(strongSelf.dataSource.objects[currentIndex + 1], nil);
                            }
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [strongSelf.searchTableView reloadData];
                        }];
                    }
                }];
            }
        }
    }
}

#pragma mark No Results / Loading More View
- (void)addNoResultsView
{
    MITViewWithCenterText *noResultsView = [[[NSBundle mainBundle] loadNibNamed:@"MITViewWithCenterText" owner:self options:nil] objectAtIndex:0];
    noResultsView.frame = self.searchTableView.frame;
    if (self.errorMessage) {
        noResultsView.overviewText.text = self.errorMessage;
        self.errorMessage = nil;
    }
    [self.view addSubview:noResultsView];
    self.messageView = noResultsView;
}

- (void)removeNoResultsView
{
    [self.messageView removeFromSuperview];
    self.messageView = nil;
}

- (void)addLoadingView
{
    MITViewWithCenterTextAndIndicator *loadingActivityView = [[[NSBundle mainBundle] loadNibNamed:@"MITViewWithCenterTextAndIndicator" owner:self options:nil] objectAtIndex:0];
    loadingActivityView.frame = self.searchTableView.frame;
    [self.view addSubview:loadingActivityView];
    self.messageActivityView = loadingActivityView;
}

- (void)removeLoadingView
{
    [self.messageActivityView removeFromSuperview];
    self.messageActivityView = nil;
}
@end