#import "MITNewsViewController.h"

#import "MITNewsConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "MITMobile.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITNewsModelController.h"
#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsCategoryDataSource.h"

#import "MITNewsListViewController.h"
#import "MITNewsGridViewController.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsSearchController.h"
#import "MITNewsCategoryViewController.h"

#import "MITViewWithCenterText.h"
#import "Reachability.h"
#import "MITResourceConstants.h"
#import "MITMobileServerConfiguration.h"

CGFloat const refreshControlTextHeight = 19;

@interface MITNewsViewController (NewsDataSource) <MITNewsStoryDataSource, MITNewsListDelegate, MITNewsGridDelegate>
- (void)reloadItems:(void(^)(NSError *error))block;
- (void)loadDataSources:(void(^)(NSError*))completion;
@end

@interface MITNewsViewController (NewsDelegate) <MITNewsStoryDelegate, MITNewsSearchDelegate, MITNewsStoryViewControllerDelegate>
@end

@interface MITNewsViewController ()
@property (nonatomic, strong) MITNewsSearchController *searchController;
@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, weak) MITViewWithCenterText *messageView;
@property (nonatomic) Reachability *internetReachability;

@property (nonatomic, weak) MITNewsCategoryViewController *weakCategoryViewController;
@property (nonatomic, weak) MITNewsStoryViewController *weakStoryDetailViewController;

#pragma mark Data Source
@property (nonatomic,strong) MITNewsCategoryDataSource *categoriesDataSource;
@property (nonatomic, copy) NSArray *dataSources;
@property (nonatomic) NSUInteger currentDataSourceIndex;

@property (nonatomic) BOOL isSingleDataSource;
@property (nonatomic) BOOL storyUpdateInProgress;
@property (nonatomic) BOOL loadingMoreStories;
@property (nonatomic, weak) MITNewsDataSource *searchDataSource;
@property (nonatomic) BOOL showSearchStories;
@property (nonatomic) CGPoint previousPositionOfMainView;
@property (nonatomic) BOOL isPreviousStateASingleDataSource;
@property (nonatomic, strong) NSDate *mainLastUpdated;

@end

@implementation MITNewsViewController

@synthesize activeViewController = _activeViewController;
@synthesize gridViewController = _gridViewController;
@synthesize listViewController = _listViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Lifecycle

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self reloadData];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateNavigationItem:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.showsFeaturedStories = NO;
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.autoresizesSubviews = YES;
}

- (void)beginReachability
{
    if (self.internetReachability) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityWithHostName:MITMobileWebGetCurrentServerURL().host];
	[self.internetReachability startNotifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
     
    if (!self.activeViewController || [self isCategoryControllerDifferentThanHome]) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid] && self.presentationStyle == MITNewsPresentationStyleGrid) {
            [self setPresentationStyle:MITNewsPresentationStyleGrid animated:animated];
        } else {
            [self setPresentationStyle:MITNewsPresentationStyleList animated:animated];
        }
    }
    
    if (!self.isSearching && !self.storyUpdateInProgress) {
        if (!self.lastUpdated) {
            [self reloadViewItems:self.refreshControl];
        } else {
            [self updateRefreshStatusWithLastUpdatedTime];
        }
        [self updateNavigationItem:YES];
    } else if (!self.storyUpdateInProgress){
        [self updateRefreshStatusWithLastUpdatedTime];
    }
    
    if (!self.storyUpdateInProgress || self.weakStoryDetailViewController) {
        return;
    }
    
    [self showRefreshControl];
    [self updateRefreshStatusWithText:@"Updating..."];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!self.refreshControl.refreshing) {
            
            [self.refreshControl endRefreshing];
            [self.refreshControl beginRefreshing];
        }
    }];
}

- (BOOL)isCategoryControllerDifferentThanHome
{
    if (self.weakCategoryViewController != NULL &&
        self.weakCategoryViewController.presentationStyle != self.presentationStyle) {
        self.presentationStyle = self.weakCategoryViewController.presentationStyle;
        return YES;
    }
    return NO;
}

#pragma mark Dynamic Properties
- (NSManagedObjectContext*)managedObjectContext
{
    return [[MITCoreDataController defaultController] mainQueueContext];
}

- (MITNewsGridViewController*)gridViewController
{
    MITNewsGridViewController *gridViewController = _gridViewController;

    if (![self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        return nil;
    } else if (!gridViewController) {
        gridViewController = [[MITNewsGridViewController alloc] init];
        gridViewController.delegate = self;
        gridViewController.dataSource = self;
        
        gridViewController.automaticallyAdjustsScrollViewInsets = NO;
        gridViewController.edgesForExtendedLayout = UIRectEdgeAll;
        _gridViewController = gridViewController;
        
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadViewItems:)
                 forControlEvents:UIControlEventValueChanged];
        refreshControl.attributedTitle = self.refreshControl.attributedTitle;
        [gridViewController.collectionView addSubview:refreshControl];
        self.refreshControl = refreshControl;
    }

    return gridViewController;
}

- (MITNewsListViewController*)listViewController
{
    MITNewsListViewController *listViewController = _listViewController;

    if (![self supportsPresentationStyle:MITNewsPresentationStyleList]) {
        return nil;
    } else if (!listViewController) {
        listViewController = [[MITNewsListViewController alloc] init];
        listViewController.delegate = self;
        listViewController.dataSource = self;

        listViewController.automaticallyAdjustsScrollViewInsets = NO;
        listViewController.edgesForExtendedLayout = UIRectEdgeAll;
        _listViewController = listViewController;
        
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadViewItems:)
                 forControlEvents:UIControlEventValueChanged];
        refreshControl.attributedTitle = self.refreshControl.attributedTitle;
        [listViewController.tableView addSubview:refreshControl];
        self.listViewController.refreshControl = refreshControl;
        self.refreshControl = refreshControl;
    }
    
    return listViewController;
}

- (MITNewsSearchController *)searchController
{
    if(!_searchController) {
        MITNewsSearchController *searchController = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            searchController = [[UIStoryboard storyboardWithName:@"News_iPad" bundle:nil] instantiateViewControllerWithIdentifier:@"searchView"];
        } else {
            searchController = [[UIStoryboard storyboardWithName:@"News_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"searchView"];

        }
        
        searchController.view.frame = self.containerView.bounds;
        searchController.delegate = self;
        _searchController = searchController;
    }
    
    return _searchController;
}

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self.searchController;
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.placeholder = @"Search";
        self.searchController.searchBar = searchBar;
        
        _searchBar = searchBar;
    }
    return _searchBar;
}

#pragma mark UI Actions
- (void)setPresentationStyle:(MITNewsPresentationStyle)style
{
    [self setPresentationStyle:style animated:NO];
}

- (void)setPresentationStyle:(MITNewsPresentationStyle)style animated:(BOOL)animated
{
    NSAssert([self supportsPresentationStyle:style], @"presentation style %ld is not supported on this device", (long)style);

    if (![self supportsPresentationStyle:style]) {
        return;
    } else if ((_presentationStyle != style) || !self.activeViewController) {
        _presentationStyle = style;

        // Figure out which view controllers we are going to be
        // transitioning from/to.
        UIViewController *fromViewController = self.activeViewController;
        UIViewController *toViewController = nil;
        
        if (_presentationStyle == MITNewsPresentationStyleGrid) {
            toViewController = self.gridViewController;
            self.gridViewController.showSingleCategory = self.isSingleDataSource;
        } else {
            toViewController = self.listViewController;
            self.listViewController.isACategoryView = self.isSingleDataSource;
        }
        // Needed to fix alignment of refreshcontrol text
        if (fromViewController) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.refreshControl beginRefreshing];
                [self.refreshControl endRefreshing];
            }];
        }
        const CGRect viewFrame = self.containerView.bounds;
        fromViewController.view.frame = viewFrame;
        fromViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        toViewController.view.frame = viewFrame;
        toViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);

        const NSTimeInterval animationDuration = (animated ? 0.25 : 0);
        _activeViewController = toViewController;
        if (!fromViewController) {
            [self addChildViewController:toViewController];

            [UIView transitionWithView:self.containerView
                              duration:animationDuration
                               options:0
                            animations:^{
                                [self.containerView addSubview:toViewController.view];
                            } completion:^(BOOL finished) {
                                [toViewController didMoveToParentViewController:self];
                                //In landscape mode we need this to show the refresh when first starting module
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    if (!self.lastUpdated) {
                                        [self startAndShowRefreshControl];
                                    }
                                }];
                            }];
        } else {
            [fromViewController willMoveToParentViewController:nil];
            [self addChildViewController:toViewController];

            [self transitionFromViewController:fromViewController
                              toViewController:toViewController
                                      duration:animationDuration
                                       options:0
                                    animations:nil
                                    completion:^(BOOL finished) {
                                        [toViewController didMoveToParentViewController:self];
                                        [fromViewController removeFromParentViewController];
                                        if (self.storyUpdateInProgress) {
                                            [self startAndShowRefreshControl];
                                        }
                                    }];
        }
    }
}

- (void)startAndShowRefreshControl
{
    if (self.storyUpdateInProgress) {
        
        if ((self.presentationStyle == MITNewsPresentationStyleGrid && self.gridViewController.collectionView.contentOffset.y == 0) || (self.presentationStyle == MITNewsPresentationStyleList && self.listViewController.tableView.contentOffset.y == 0)) {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^(void){
                [self showRefreshControl];
            } completion:nil];
            
            [self.refreshControl beginRefreshing];
            [self updateRefreshStatusWithText:@"Updating..."];
        }
    }
}

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem *)sender
{
    if (self.refreshControl.refreshing) {
        self.previousPositionOfMainView = CGPointMake(0, 0);
    } else if (_presentationStyle == MITNewsPresentationStyleGrid) {
        self.previousPositionOfMainView = self.gridViewController.collectionView.contentOffset;
    } else {
        self.previousPositionOfMainView = self.listViewController.tableView.contentOffset;
    }
    self.isPreviousStateASingleDataSource = self.isSingleDataSource;
    self.searching = YES;
    self.mainLastUpdated = self.lastUpdated;
    [self updateNavigationItem:NO];
    [self addChildViewController:self.searchController];
    [self.containerView addSubview:self.searchController.view];
    [self.searchController didMoveToParentViewController:self];
    [UIView animateWithDuration:(0.33)
                          delay:0.
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         self.searchController.view.alpha = .5;
                     } completion:nil];
    
    [self.searchBar becomeFirstResponder];
}

- (IBAction)showStoriesAsGrid:(UIBarButtonItem *)sender
{
    if (!self.messageView && !self.loadingMoreStories) {
        self.presentationStyle = MITNewsPresentationStyleGrid;
        [self updateNavigationItem:YES];
    }
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    if (!self.messageView && !self.loadingMoreStories) {
        self.presentationStyle = MITNewsPresentationStyleList;
        [self updateNavigationItem:YES];
    }
}

- (void)reloadSearchData
{
    self.lastUpdated = self.searchDataSource.refreshedAt;
    [self updateRefreshStatusWithLastUpdatedTime];
    [self reloadData];
}

- (void)reloadData
{
    if (self.activeViewController == _gridViewController) {
        [self.gridViewController.collectionView reloadData];
    } else if (self.activeViewController == _listViewController) {
        [self.listViewController.tableView reloadData];
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSURL *url = [NSURL URLWithString:alertView.message];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    if (_presentationStyle == MITNewsPresentationStyleList) {
        [self.listViewController.tableView deselectRowAtIndexPath:[self.listViewController.tableView indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark Utility Methods
- (BOOL)supportsPresentationStyle:(MITNewsPresentationStyle)style
{
    if (style == MITNewsPresentationStyleList) {
        return YES;
    } else if (style == MITNewsPresentationStyleGrid) {
        const CGFloat minimumWidthForGrid = 768.;
        const CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
        
        return (boundsWidth >= minimumWidthForGrid);
    }
    return NO;
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];

    if (self.presentationStyle == MITNewsPresentationStyleList) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
            UIImage *gridImage = [UIImage imageNamed:MITImageBarButtonGrid];
            UIBarButtonItem *gridItem = [[UIBarButtonItem alloc] initWithImage:gridImage style:UIBarButtonSystemItemStop target:self action:@selector(showStoriesAsGrid:)];
            [rightBarItems addObject:gridItem];
        }
    } else if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleList]) {
            UIImage *listImage = [UIImage imageNamed:MITImageBarButtonList];
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesAsList:)];
            [rightBarItems addObject:listItem];
        }
    }
    if (self.searching) {
        
        UIBarButtonItem *cancelSearchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.searchController action:@selector(searchBarCancelButtonClicked)];
        [rightBarItems addObject:cancelSearchItem];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.searchBar.frame = CGRectMake(0, 0, 280, 44);
        } else {
            self.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
        }
        if (self.isSingleDataSource) {
            self.navigationItem.hidesBackButton = YES;
        } else {
            self.navigationItem.leftBarButtonItem.tintColor = [UIColor clearColor];
            self.navigationItem.leftBarButtonItem.enabled = NO;
        }
        
        UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
        [rightBarItems addObject:searchBarItem];
        self.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        [self.navigationItem setTitle:@""];

    } else {
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonWasTriggered:)];
        [rightBarItems addObject:searchItem];
        self.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        self.navigationItem.leftBarButtonItem.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        [self.navigationItem setTitle:@"MIT News"];
    }
    
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
   
    // This width is set here because we do not know the position of
    // the searchbar until we add it to the navigationbar
    // Mark Novak 12-11-14
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        CGRect rect = self.searchBar.frame;
        rect.size.width = rect.size.width + self.searchBar.frame.origin.x - 8;
        rect.origin.x = 0;
        self.searchBar.frame = rect;
    }
}

#pragma mark Story Refreshing
- (void)reloadViewItems:(UIRefreshControl *)refreshControl
{
    if (self.loadingMoreStories) {
        [refreshControl endRefreshing];
        return;
    }
    
    if (self.storyUpdateInProgress) {
        return;
    }
    
    self.storyUpdateInProgress = YES;
    if (self.messageView) {
        [self removeNoResultsView];
    }
    
    __weak MITNewsViewController *weakSelf = self;
    __weak UIRefreshControl *weakRefresh = refreshControl;
    if (refreshControl.refreshing) {
        [self updateRefreshStatusWithText:@"Updating..."];
    }
    [self reloadItems:^(NSError *error) {
        self.storyUpdateInProgress = NO;
        MITNewsViewController *strongSelf = weakSelf;
        UIRefreshControl *strongRefresh = weakRefresh;
        
        if (!strongSelf) {
            return;
        }
        if (!strongRefresh) {
            return;
        }

        if (error) {
            DDLogWarn(@"update failed; %@",error);
            if (error.code == NSURLErrorNotConnectedToInternet) {
                [strongSelf updateRefreshStatusWithText:@"No Internet Connection"];
            } else {
                [strongSelf updateRefreshStatusWithText:@"Failed..."];
            }
            if ([strongSelf.dataSources count] == 0) {
                [strongSelf addNoResultsViewWithMessage:refreshControl.attributedTitle.string];
                
            } else {
                BOOL *storyHasBeenDownloaded = NO;
                for (MITNewsDataSource *datasource in strongSelf.dataSources) {
                    if ([datasource.objects count] != 0) {
                        storyHasBeenDownloaded = YES;
                        break;
                    }
                }
                if (!storyHasBeenDownloaded) {
                    [strongSelf addNoResultsViewWithMessage:refreshControl.attributedTitle.string];
                }
                if (strongRefresh.refreshing) {
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^{
                        [strongRefresh endRefreshing];
                    });
                }
            }
            if (!self.lastUpdated && ![self.dataSources count]) {
                 [self beginReachability];
            }
        } else {
            strongSelf.lastUpdated = [NSDate date];
            [strongSelf updateRefreshStatusWithLastUpdatedTime];
            if (strongRefresh.refreshing) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^{
                    [strongSelf.refreshControl endRefreshing];
                });
            }
            if (strongSelf.internetReachability) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
                [strongSelf.internetReachability stopNotifier];
                strongSelf.internetReachability = nil;
            }
        }
    }];
}

#pragma mark No Results / Loading More View
- (void)addNoResultsViewWithMessage:(NSString *)message
{
    MITViewWithCenterText *noResultsView = [[[NSBundle mainBundle] loadNibNamed:@"MITViewWithCenterText" owner:self options:nil] objectAtIndex:0];
    noResultsView.frame = self.activeViewController.view.frame;
    noResultsView.overviewText.text = message;
    [self.view addSubview:noResultsView];
    self.messageView = noResultsView;
}

- (void)removeNoResultsView
{
    [self.messageView removeFromSuperview];
    self.messageView = nil;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    if (!self.lastUpdated) {
        Reachability* reachabilityObject = [notification object];
        NetworkStatus statusOfNetwork = [reachabilityObject currentReachabilityStatus];
        if (statusOfNetwork != NotReachable) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.refreshControl beginRefreshing];
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void){
                    [self showRefreshControl];
                } completion:nil];
            }];
            [self reloadViewItems:self.refreshControl];
        }
    }
}

- (void)showRefreshControl
{
    CGFloat textHeight = 0;
    if (!self.refreshControl.attributedTitle.string) {
        textHeight = refreshControlTextHeight;
    }
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        [self.gridViewController.collectionView setContentOffset:CGPointMake(0, - (self.refreshControl.frame.size.height + textHeight)) animated:YES];
    } else {
        [self.listViewController.tableView setContentOffset:CGPointMake(0, - (self.refreshControl.frame.size.height + textHeight)) animated:YES];
    }
}

#pragma mark Refresh Control Text
- (void)updateRefreshStatusWithLastUpdatedTime
{
    if (self.lastUpdated) {
        NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                            toDate:[NSDate date]];
        NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
        [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:updateText]];
    }
}

- (void)updateRefreshStatusWithText:(NSString *)refreshText
{
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:refreshText]];
}

- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError *))block
{
    if (self.storyUpdateInProgress || self.loadingMoreStories || ![self canLoadMoreItemsForCategoryInSection:section]) {
        if (block) {
            block(nil);
        }
        return;
    }
    
    [self setNewsStoryUpdateInProgress:YES];
    [self updateLoadingCellWithError:nil];
    self.loadingMoreStories = YES;
    
    __weak MITNewsViewController *weakSelf = self;
    [self loadMoreItemsForCategoryInSection:section
                                 completion:^(NSError *error) {
                                     
                                     MITNewsViewController *strongSelf = weakSelf;
                                     if (!strongSelf) {
                                         return;
                                     }
                                     [strongSelf setNewsStoryUpdateInProgress:NO];
                                     strongSelf.loadingMoreStories = NO;
                                     
                                     if (error) {
                                         DDLogWarn(@"failed to get more stories from datasource %@",strongSelf.dataSources[section]);

                                         [self storyUpdateDidFinishWithError:error];
                                         [strongSelf updateLoadingCellWithError:error];
                                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
                                         dispatch_after(popTime, dispatch_get_main_queue(), ^{
                                             if (self.presentationStyle == MITNewsPresentationStyleGrid) {
                                                 self.gridViewController.errorMessage = nil;
                                             }
                                             [strongSelf updateLoadingCellWithError:error];
                                         });
                                     } else {
                                         DDLogVerbose(@"retrieved more stores from datasource %@",strongSelf.dataSources[section]);
                                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                             [strongSelf reloadData];
                                         }];
                                     }
                                     if (block) {
                                         block(error);
                                     }
                                 }];
}

#pragma mark setters
- (void)storyUpdateDidFinishWithError:(NSError *)error
{
    NSString *message = nil;
    if (error.code == NSURLErrorNotConnectedToInternet) {
        message = @"No Internet Connection";
    } else {
        message = @"Failed...";
    }
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        self.gridViewController.errorMessage = message;
        [self.gridViewController updateLoadingMoreCellString];
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        self.listViewController.errorMessage = message;
    }
}

- (void)setNewsStoryUpdateInProgress:(BOOL)progress
{
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        self.gridViewController.storyUpdateInProgress = progress;
        [self.gridViewController updateLoadingMoreCellString];
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        self.listViewController.storyUpdateInProgress = progress;
    }
}

- (void)updateLoadingCellWithError:(NSError *)error
{
    MITNewsDataSource *dataSource = nil;
    if (self.showSearchStories) {
        dataSource = self.searchDataSource;
    } else {
        dataSource = self.dataSources[0];
    }
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        if (self.gridViewController.errorMessage) {
            [self storyUpdateDidFinishWithError:error];
        } else {
            [self setNewsStoryUpdateInProgress:self.gridViewController.storyUpdateInProgress];
        }
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        [self.listViewController.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end

@implementation MITNewsViewController (NewsDataSource)

- (void)loadDataSources:(void (^)(NSError*))completion
{
    MITNewsCategoryDataSource *categoriesDataSource = [[MITNewsCategoryDataSource alloc] init];

    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    if (self.showsFeaturedStories) {
        MITNewsDataSource *featuredDataSource = [MITNewsStoriesDataSource featuredStoriesDataSource];
        featuredDataSource.maximumNumberOfItemsPerPage = 5;
        [dataSources addObject:featuredDataSource];
    }

    [categoriesDataSource.categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
        MITNewsDataSource *dataSource = [MITNewsStoriesDataSource dataSourceForCategory:category];

        [dataSources addObject:dataSource];
    }];

    self.categoriesDataSource = categoriesDataSource;
    self.dataSources = dataSources;
    [self reloadData];

    // TODO: Rework the update process; this is incredibly awkward
    __weak MITNewsViewController *weakSelf = self;
    [self.categoriesDataSource refresh:^(NSError *error) {
        MITNewsViewController *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }

        if (error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (completion) {
                    completion(error);
                }
            }];

            return;
        }

        NSMutableArray *dataSources = [[NSMutableArray alloc] init];
        if (self.showsFeaturedStories) {
            MITNewsDataSource *featuredDataSource = [MITNewsStoriesDataSource featuredStoriesDataSource];
            featuredDataSource.maximumNumberOfItemsPerPage = 5;
            [dataSources addObject:featuredDataSource];
        }

        [blockSelf.categoriesDataSource.categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
            MITNewsDataSource *dataSource = [MITNewsStoriesDataSource dataSourceForCategory:category];
            [dataSources addObject:dataSource];
        }];

        blockSelf.dataSources = dataSources;
        [blockSelf refreshDataSources:completion];
    }];
}

- (void)refreshDataSources:(void (^)(NSError*))completion
{
    dispatch_group_t refreshGroup = dispatch_group_create();
    __block NSError *updateError = nil;

    [self.dataSources enumerateObjectsUsingBlock:^(MITNewsDataSource *dataSource, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(refreshGroup);
        
        [dataSource refresh:^(NSError *error) {
            if (error) {
                DDLogWarn(@"failed to refresh data source %@",dataSource);

                if (!updateError) {
                    updateError = error;
                }
            } else {
                DDLogVerbose(@"refreshed data source %@",dataSource);
            }

            dispatch_group_leave(refreshGroup);
        }];
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_group_wait(refreshGroup, DISPATCH_TIME_FOREVER);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self reloadData];
            
            if (completion) {
                completion(updateError);
            }
        }];
    });
}

- (MITNewsDataSource*)dataSourceForCategoryInSection:(NSUInteger)section
{
    if (self.showSearchStories) {
        return self.searchDataSource;
    } else {
        return self.dataSources[section];
    }
}

- (BOOL)canLoadMoreItemsForCategoryInSection:(NSUInteger)section
{
    MITNewsDataSource *dataSource = nil;
    if (self.showSearchStories) {
        dataSource = self.searchDataSource;
    } else {
        dataSource = [self dataSourceForCategoryInSection:section];
    }
    return [dataSource hasNextPage];
}

- (void)loadMoreItemsForCategoryInSection:(NSUInteger)section completion:(void(^)(NSError *error))block
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    [dataSource nextPage:block];
}

- (BOOL)refreshItemsForCategoryInSection:(NSUInteger)section completion:(void(^)(NSError *error))block
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    [dataSource refresh:block];
    return YES;
}

- (void)reloadItems:(void(^)(NSError *error))block
{
    if (self.showSearchStories) {
        [self.searchController.dataSource refresh:^(NSError *error) {
            if (error) {
                DDLogWarn(@"failed to refresh data source %@",self.searchDataSource);
            } else {
                DDLogVerbose(@"refreshed data source %@",self.searchDataSource);
                [self reloadData];
            }
            if (block) {
                block(error);
            }
        }];
    } else if ([self.dataSources count]) {
        [self refreshDataSources:block];
    } else {
        [self loadDataSources:block];
    }
}

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController
{
    if (self.showSearchStories) {
        return 1;
    }
    return [self.dataSources count];
}

- (NSString*)viewController:(UIViewController*)viewController titleForCategoryInSection:(NSUInteger)section
{
    if (self.showSearchStories) {
        return nil;
    }
    if (self.showsFeaturedStories && (section == 0)) {
        return @"Featured";
    } else {
        __block NSString *title = nil;
        if (self.showsFeaturedStories) {
            --section;
        }

        MITNewsCategory *category = self.categoriesDataSource.categories[section];
        [category.managedObjectContext performBlockAndWait:^{
            title = category.name;
        }];

        return title;
    }
}

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    if (self.showSearchStories) {
        return [self.searchDataSource.objects count];
    }
    if (self.isSingleDataSource) {
        MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
        return [dataSource.objects count];
    }
    if (self.showsFeaturedStories && (section == 0)) {
        return 5;
    } else {
        MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
        return MIN([dataSource.objects count],10);
    }
}

- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section
{
    if (self.showSearchStories) {
        if ([self.searchDataSource.objects count] <= index) {
            return nil;
        }
        return self.searchDataSource.objects[index];
    }
    
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    if ([dataSource.objects count] <= index) {
        return nil;
    }
    return dataSource.objects[index];
}

- (BOOL)viewController:(UIViewController*)viewController isFeaturedCategoryInSection:(NSUInteger)section
{
    if (self.showsFeaturedStories) {
        return (section == 0);
    } else {
        return NO;
    }
}
@end

#pragma mark MITNewsStoryDetailPagingDelegate

@implementation MITNewsViewController (NewsDelegate)

- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryInSection:(NSUInteger)index;
{
    [self performSegueWithIdentifier:@"showCategory" sender:[NSIndexPath indexPathForItem:0 inSection:index]];
    return nil;
}

- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section;
{
    self.currentDataSourceIndex = section;
 
    MITNewsStory *story = [self viewController:self storyAtIndex:index forCategoryInSection:section];
    if (!story) {
        return nil;
    }
    __block BOOL isExternalStory = NO;
    __block NSURL *externalURL = nil;
    [self.managedObjectContext performBlockAndWait:^{
        if ([story.type isEqualToString:MITNewsStoryExternalType]) {
            isExternalStory = YES;
            externalURL = story.sourceURL;
        }
    }];
    
    if (isExternalStory) {
        NSString *message = [NSString stringWithFormat:@"Open in Safari?"];
        UIAlertView *willOpenInExternalBrowserAlertView = [[UIAlertView alloc] initWithTitle:message message:[externalURL absoluteString] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
        [willOpenInExternalBrowserAlertView show];
    } else {
        [self performSegueWithIdentifier:@"showStoryDetail" sender:[NSIndexPath indexPathForItem:index inSection:section]];
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {

            NSIndexPath *indexPath = sender;

            MITNewsStory *story = [self viewController:self storyAtIndex:indexPath.row forCategoryInSection:indexPath.section];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
                storyDetailViewController.delegate = self;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
                self.weakStoryDetailViewController = storyDetailViewController;
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else if ([segue.identifier isEqualToString:@"showCategory"]) {
        if ([destinationViewController isKindOfClass:[MITNewsCategoryViewController class]]) {
            
            NSIndexPath *indexPath = sender;
            
            MITNewsCategoryViewController *newsCategoryViewController  = (MITNewsCategoryViewController*)destinationViewController;
            newsCategoryViewController.previousPresentationStyle = _presentationStyle;
            newsCategoryViewController.dataSource = self.dataSources[indexPath.section];
            newsCategoryViewController.categoryTitle = [self viewController:self titleForCategoryInSection:indexPath.section];
            self.weakCategoryViewController = newsCategoryViewController;
        
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
    
    MITNewsDataSource *dataSource = nil;
    if (self.showSearchStories) {
        dataSource = self.searchDataSource;
    } else {
        dataSource = self.dataSources[self.currentDataSourceIndex];
    }
    
    NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
    if (currentIndex == NSNotFound) {
        if (block) {
            block(nil, nil);
        }
        return;
    }
    
    if (currentIndex + 1 < [dataSource.objects count]) {
        if(block) {
            block(dataSource.objects[currentIndex +1], nil);
        }
    } else {
        if (![dataSource hasNextPage]) {
            if (block) {
                block(nil, nil);
            }
            return;
        }
        [dataSource nextPage:^(NSError *error) {
            if (error) {
                DDLogWarn(@"failed to get more stories from datasource %@",dataSource);
                
                if (block) {
                    block(nil, error);
                }
            } else {
                DDLogVerbose(@"retrieved more stores from datasource %@",dataSource);
                NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
                
                if (currentIndex + 1 < [dataSource.objects count]) {
                    if(block) {
                        block(dataSource.objects[currentIndex + 1], nil);
                    }
                }
            }
        }];
    }
}

- (void)hideSearchField
{
    self.searchBar = nil;
    [self.searchController willMoveToParentViewController:nil];
    [self.searchController.view removeFromSuperview];
    [self.searchController removeFromParentViewController];
    self.searchController = nil;
    self.searching = NO;
    [self updateNavigationItem:NO];
    [self changeToMainStories];
}

- (void)changeToMainStories
{
    self.showSearchStories = NO;
    self.isSingleDataSource = self.isPreviousStateASingleDataSource;
    self.lastUpdated = self.mainLastUpdated;
    [self updateRefreshStatusWithLastUpdatedTime];
    if (_presentationStyle == MITNewsPresentationStyleGrid) {
        self.gridViewController.showSingleCategory = self.isSingleDataSource;
    } else {
        self.listViewController.isACategoryView = self.isSingleDataSource;
    }
    [self reloadData];
    if (_presentationStyle == MITNewsPresentationStyleGrid) {
        [self.gridViewController.collectionView setContentOffset:self.previousPositionOfMainView];
    } else {
        [self.listViewController.tableView setContentOffset:self.previousPositionOfMainView];
    }
}

- (void)changeToSearchStories
{
    self.searchDataSource = self.searchController.dataSource;
    if (!self.showSearchStories || !self.isSingleDataSource) {
        self.showSearchStories = YES;
        self.isSingleDataSource = YES;
        if (_presentationStyle == MITNewsPresentationStyleGrid) {
            self.gridViewController.showSingleCategory = self.isSingleDataSource;
        } else {
            self.listViewController.isACategoryView = self.isSingleDataSource;
        }
        [self reloadData];
    }
}

@end
