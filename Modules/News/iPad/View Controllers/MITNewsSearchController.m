#import "MITNewsSearchController.h"
#import "MITNewsModelController.h"
#import "MITNewsRecentSearchController.h"
#import "MITNewsConstants.h"
#import "MITNewsStory.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStoryViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "MITLoadingActivityView.h"
#import "MITViewWithCenterTextAndIndicator.h"
#import "MITViewWithCenterText.h"
#import "MITNewsCustomWidthTableViewCell.h"
#import "MITPopoverBackgroundView.h"

@interface MITNewsSearchController() <UIPopoverControllerDelegate, MITNewsStoryViewControllerDelegate>
@property (nonatomic, strong) MITNewsRecentSearchController *recentSearchController;
@property (nonatomic, strong) UIPopoverController *recentSearchPopoverController;
@property (nonatomic) BOOL unwindFromStoryDetail;
@property (nonatomic, weak) MITViewWithCenterTextAndIndicator *messageActivityView;
@property (nonatomic, weak) MITViewWithCenterText *messageView;
@property (nonatomic, strong) NSString *errorMessage;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *resignSearchTapGestureRecognizer;
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

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
        [self bringBackStories];
        self.view.alpha = .5;
    } else {
        [self hideStories];
        self.view.alpha = 0;
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
    self.view.alpha = .5;
    if ([searchBar.text isEqualToString:@""]) {
        [self bringBackStories];
    } else {
        [self hideStories];
    }
    [self removeNoResultsView];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self showSearchRecents];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""]) {
        [self.view addGestureRecognizer:self.resignSearchTapGestureRecognizer];
        [self bringBackStories];
        self.view.alpha = .5;
        [self clearTable];
    } else {
        [self.view removeGestureRecognizer:self.resignSearchTapGestureRecognizer];
        [self hideStories];
        self.view.alpha = .5;
    }
    [self.recentSearchController filterResultsUsingString:searchText];
}

- (void)clearTable
{
    self.dataSource = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self reloadData];
    }];
}

#pragma mark - search
- (void)getResultsForString:(NSString *)searchTerm
{
    [self.view removeGestureRecognizer:self.resignSearchTapGestureRecognizer];
    [self removeNoResultsView];
    [self addLoadingView];
    [self reloadData];
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
            [self hideStories];
        }
    }];
    [self.searchBar resignFirstResponder];
    [self.recentSearchPopoverController dismissPopoverAnimated:YES];
    [UIView animateWithDuration:0.33
                          delay:0.
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         [self hideStories];
                         self.view.alpha = 0;
                     } completion:^(BOOL finished) {
                         
                     }];
}
/*
- (void)getMoreStories:(void (^)(NSError *))completion
{
    if (![self.dataSource hasNextPage] || self.dataSource.isUpdating) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    __weak MITNewsSearchController *weakSelf = self;
    _storyUpdateInProgress = YES;
    [self.dataSource nextPage:^(NSError *error) {
        _storyUpdateInProgress = NO;

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
        if (completion) {
            completion(error);
        }
    }];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.searchTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}
 */

#pragma mark - hide/show Recents
- (void)hideSearchRecents
{
    if (self.recentSearchPopoverController != nil && self.recentSearchController.confirmSheet == nil) {
        [self.recentSearchPopoverController dismissPopoverAnimated:YES];
        self.recentSearchPopoverController = nil;
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
    if (self.view.alpha == .5) {
        [self hideSearchField];
    }
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.recentSearchPopoverController = nil;
}

- (IBAction)tappedHideSearchFieldArea:(id)sender
{
    [self hideSearchField];
}

#pragma mark No Results / Loading More View
- (void)addNoResultsView
{
    MITViewWithCenterText *noResultsView = [[[NSBundle mainBundle] loadNibNamed:@"MITViewWithCenterText" owner:self options:nil] objectAtIndex:0];
    noResultsView.frame = self.view.frame;
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
    loadingActivityView.frame = self.view.frame;
    [self.view addSubview:loadingActivityView];
    self.messageActivityView = loadingActivityView;
}

- (void)removeLoadingView
{
    [self.messageActivityView removeFromSuperview];
    self.messageActivityView = nil;
}

- (void)hideStories
{
    [self.delegate hideStories];
}

- (void)bringBackStories
{
    [self.delegate bringBackStories];
}

- (void)reloadData
{
    [self.delegate reloadData];
}

@end
