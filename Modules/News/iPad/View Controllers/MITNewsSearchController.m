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

static NSUInteger loadingActivityViewTag = (int)"loadingActivityView";
static NSUInteger noResultsViewTag = (int)"noResultsView";

@interface MITNewsSearchController (NewsDataSource) <UIPopoverControllerDelegate, MITNewsStoryViewControllerDelegate>

@end

@interface MITNewsSearchController()
@property (strong, nonatomic) MITNewsRecentSearchController *recentSearchController;
@property (nonatomic, strong) UIPopoverController *recentSearchPopoverController;
@property (nonatomic) BOOL unwindFromStoryDetail;
@property (nonatomic) MITNewsDataSource *dataSource;

@end

@implementation MITNewsSearchController {
    BOOL _storyUpdateInProgress;
    BOOL _storyUpdatedFailed;
}

@synthesize recentSearchController = _recentSearchController;

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

#pragma mark - SearchBar

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
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
    UIView *view = [self.view viewWithTag:loadingActivityViewTag];
    if (view) {
        view.alpha = 1;
    }
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
    UIView *view = [self.view viewWithTag:loadingActivityViewTag];
    if (view) {
        view.alpha = .5;
    }
    searchBar.showsCancelButton = YES;
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
    __block NSError *updateError = nil;
    self.dataSource = [MITNewsStoriesDataSource dataSourceForQuery:searchTerm];
    [self.dataSource refresh:^(NSError *error) {
        if (error) {
            DDLogWarn(@"failed to refresh data source %@",self.dataSource);
            
            if (!updateError) {
                updateError = error;
            }
        } else {
            DDLogVerbose(@"refreshed data source %@",self.dataSource);
            [self removeLoadingView];
            
            if ([self.dataSource.objects count] == 0) {
                [self addNoResultsView];
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.searchTableView reloadData];
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
        [self.dataSource nextPage:^(NSError *error) {
            _storyUpdateInProgress = FALSE;
            if (error) {
                DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                _storyUpdatedFailed = TRUE;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [NSTimer scheduledTimerWithTimeInterval:2
                                                     target:self
                                                   selector:@selector(clearFailAfterTwoSeconds)
                                                   userInfo:nil
                                                    repeats:NO];
                }];
            } else {
                DDLogVerbose(@"refreshed data source %@",self.dataSource);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.searchTableView reloadData];
                }];
            }
        }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    _storyUpdatedFailed = FALSE;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
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
    if (identifier == MITNewsLoadMoreCellIdentifier && _storyUpdatedFailed) {
        cell.textLabel.text = @"Failed...";
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
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self getMoreStories];
        }
    }
        else {
        MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
        if (story) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"News_iPad" bundle:nil];
            MITNewsStoryViewController *storyDetailViewController = [storyBoard instantiateViewControllerWithIdentifier:@"NewsStoryView"];
            storyDetailViewController.delegate = self;
            NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            managedObjectContext.parentContext = self.managedObjectContext;
            storyDetailViewController.managedObjectContext = managedObjectContext;
            storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
            self.unwindFromStoryDetail = YES;
            [self.navigationController pushViewController:storyDetailViewController animated:YES];
            
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark MITNewsStoryDetailPagingDelegate

- (void)storyAfterStory:(MITNewsStory *)story return:(void (^)(MITNewsStory *, NSError *))block
{
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
    if (currentIndex != NSNotFound) {
        
        if (currentIndex + 1 < [self.dataSource.objects count]) {
            if(block) {
                block(self.dataSource.objects[currentIndex +1], nil);
            }
        } else {
            __block NSError *updateError = nil;
            if ([self.dataSource hasNextPage]) {
                
                [self.dataSource nextPage:^(NSError *error) {
                    if (error) {
                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                        
                        if (!updateError) {
                            updateError = error;
                        }
                    } else {
                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                        NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
                        
                        if (currentIndex + 1 < [self.dataSource.objects count]) {
                            if(block) {
                                block(self.dataSource.objects[currentIndex + 1], nil);
                            }
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.searchTableView reloadData];
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
    noResultsView.tag = noResultsViewTag;
    [self.view addSubview:noResultsView];
}

- (void)removeNoResultsView
{
    UIView *view = [self.view viewWithTag:noResultsViewTag];
    if (view) {
        [view removeFromSuperview];
    }
}

- (void)addLoadingView
{
    MITViewWithCenterTextAndIndicator *loadingActivityView = [[[NSBundle mainBundle] loadNibNamed:@"MITViewWithCenterTextAndIndicator" owner:self options:nil] objectAtIndex:0];
    loadingActivityView.frame = self.searchTableView.frame;
    loadingActivityView.tag = loadingActivityViewTag;
    [self.view addSubview:loadingActivityView];
}

- (void)removeLoadingView
{
    UIView *view = [self.view viewWithTag:loadingActivityViewTag];
    if (view) {
        [view removeFromSuperview];
    }
}
@end