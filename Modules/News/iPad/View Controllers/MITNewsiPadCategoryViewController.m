#import "MITNewsiPadCategoryViewController.h"
#import "MITNewsCategoryListViewController.h"
#import "MITNewsCategoryGridViewController.h"
#import "MITCoreData.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsConstants.h"
#import "MITAdditions.h"

@interface MITNewsiPadCategoryViewController (NewsDataSource) <MITNewsStoryDataSource>
@end

@interface MITNewsiPadCategoryViewController (NewsDelegate) <MITNewsStoryDelegate, MITNewsStoryViewControllerDelegate>
@end

@interface MITNewsiPadCategoryViewController () <MITNewsListDelegate, MITNewsGridDelegate>
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet MITNewsCategoryGridViewController *gridViewController;
@property (nonatomic, weak) IBOutlet MITNewsCategoryListViewController *listViewController;

@property (nonatomic, readonly, weak) UIViewController *activeViewController;
@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL movingBackFromStory;

@property(strong) id dataSourceDidEndUpdatingToken;
@end

@implementation MITNewsiPadCategoryViewController {
    BOOL _isTransitioningToPresentationStyle;
    BOOL _storyUpdateInProgress;
    BOOL _loadingMoreStories;
}

@synthesize presentationStyle = _presentationStyle;
@synthesize activeViewController = _activeViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.showsFeaturedStories = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.lastUpdated = self.dataSource.refreshedAt;
    [super viewWillAppear:animated];
    
    if (self.previousPresentationStyle) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid] && self.previousPresentationStyle == MITNewsPresentationStyleGrid) {
            [self setPresentationStyle:MITNewsPresentationStyleGrid animated:animated];
        } else {
            [self setPresentationStyle:MITNewsPresentationStyleList animated:animated];
        }
        self.previousPresentationStyle = nil;
    }
    [self updateNavigationItem:YES];
    if (self.dataSource.isUpdating) {

        __weak MITNewsiPadCategoryViewController *weakSelf = self;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        self.dataSourceDidEndUpdatingToken = [center addObserverForName:MITNewsDataSourceDidEndUpdatingNotification object:self.dataSource
                             queue:nil usingBlock:^(NSNotification *note){
                                 MITNewsiPadCategoryViewController *strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return;
                                 }
                                 [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.dataSourceDidEndUpdatingToken name:MITNewsDataSourceDidEndUpdatingNotification object:strongSelf.dataSource];

                                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
                                 dispatch_after(popTime, dispatch_get_main_queue(), ^{
                                     [strongSelf.refreshControl endRefreshing];
                                 });
                                 [strongSelf updateRefreshStatusWithLastUpdatedTime];
                             }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.refreshControl beginRefreshing];
        }];
        [self updateRefreshStatusWithText:@"Updating..."];
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.movingBackFromStory && self.dataSource.refreshedAt) {
        [self intervalUpdate];
        self.movingBackFromStory = YES;
    }
}

- (MITNewsCategoryGridViewController*)gridViewController
{
    MITNewsCategoryGridViewController *gridViewController = _gridViewController;
    
    if (![self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        return nil;
    } else if (!gridViewController) {
        gridViewController = [[MITNewsCategoryGridViewController alloc] init];
        gridViewController.delegate = self;
        gridViewController.dataSource = self;
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

- (MITNewsCategoryListViewController*)listViewController
{
    MITNewsCategoryListViewController *listViewController = _listViewController;
    
    if (![self supportsPresentationStyle:MITNewsPresentationStyleList]) {
        return nil;
    } else if (!listViewController) {
        listViewController = [[MITNewsCategoryListViewController alloc] init];
        listViewController.delegate = self;
        listViewController.dataSource = self;
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

#pragma mark UI Actions
- (void)setPresentationStyle:(MITNewsPresentationStyle)style
{
    [self setPresentationStyle:style animated:NO];
}

- (void)setPresentationStyle:(MITNewsPresentationStyle)style animated:(BOOL)animated
{
    NSAssert([self supportsPresentationStyle:style], @"presentation style %d is not supported on this device", style);
    
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
        } else {
            toViewController = self.listViewController;
        }
        // Needed to fix alignment of refreshcontrol text
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.refreshControl beginRefreshing];
            [self.refreshControl endRefreshing];
        }];
        const CGRect viewFrame = self.containerView.bounds;
        fromViewController.view.frame = viewFrame;
        toViewController.view.frame = viewFrame;
        
        const NSTimeInterval animationDuration = (animated ? 0.25 : 0);
        _isTransitioningToPresentationStyle = YES;
        _activeViewController = toViewController;
        if (!fromViewController) {
            [self addChildViewController:toViewController];
            
            [UIView transitionWithView:self.containerView
                              duration:animationDuration
                               options:0
                            animations:^{
                                [self.containerView addSubview:toViewController.view];
                            } completion:^(BOOL finished) {
                                _isTransitioningToPresentationStyle = NO;
                                [toViewController didMoveToParentViewController:self];
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
                                        _isTransitioningToPresentationStyle = NO;
                                        [toViewController didMoveToParentViewController:self];
                                        [fromViewController removeFromParentViewController];
                                    }];
        }
    }
}

- (void)updateLoadingCell
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.activeViewController == self.gridViewController) {
            [self.gridViewController.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]]];
        } else if (self.activeViewController == self.listViewController) {
            [self.listViewController.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (IBAction)showStoriesAsGrid:(UIBarButtonItem *)sender
{
    if (!_storyUpdateInProgress) {
        self.presentationStyle = MITNewsPresentationStyleGrid;
        [super updateNavigationItem:YES];
    }
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    if (!_storyUpdateInProgress) {
        self.presentationStyle = MITNewsPresentationStyleList;
        [super updateNavigationItem:YES];
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
    [super updateNavigationItem:animated];
    
    if (self.searching) {
        self.navigationItem.hidesBackButton = YES;
    } else {
        [self.navigationItem setTitle:self.categoryTitle];
        self.navigationItem.hidesBackButton = NO;
    }
}

#pragma mark Story Refreshing
- (void)reloadViewItems:(UIRefreshControl *)refreshControl;
{
    if (_loadingMoreStories) {
        [refreshControl endRefreshing];
        return;
    }
    
    if (_storyUpdateInProgress || self.dataSource.isUpdating) {
        return;
    }
    
    _storyUpdateInProgress = YES;
    [self updateRefreshStatusWithText:@"Updating..."];
    
    __weak MITNewsiPadCategoryViewController *weakSelf = self;
    __weak UIRefreshControl *weakRefresh = refreshControl;

    [self refreshItemsForCategoryInSection:0 completion:^(NSError *error) {
        _storyUpdateInProgress = NO;
        MITNewsiPadCategoryViewController *strongSelf = weakSelf;
        UIRefreshControl *strongRefresh = weakRefresh;

        if (!strongSelf) {
            return;
        }
        if (error) {
            if (!strongRefresh) {
                return;
            }
            DDLogWarn(@"update failed; %@",error);
            strongSelf.refreshControl = strongRefresh;
            if (error.code == NSURLErrorNotConnectedToInternet) {
                [strongSelf updateRefreshStatusWithText:@"No Internet Connection"];
            } else {
                [strongSelf updateRefreshStatusWithText:@"Failed..."];
            }
            if (strongRefresh.refreshing) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^{
                    [strongRefresh endRefreshing];
                });
            }
        } else {
            [strongSelf reloadData];
            if (!strongRefresh) {
                return;
            }
            strongSelf.refreshControl = strongRefresh;
            [strongSelf updateRefreshStatusWithLastUpdatedTime];
 
            if (strongRefresh.refreshing) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^{
                    [strongRefresh endRefreshing];
                });
            }
        }
    }];
}

- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError *))block
{
    if (![self canLoadMoreItemsForCategoryInSection:section] || _storyUpdateInProgress) {
        if (block) {
            block(nil);
        }
        return;
    }
    _storyUpdateInProgress = YES;
    _loadingMoreStories = YES;
    [self setProgress:YES];
    
    [self updateLoadingCell];
    
    __weak MITNewsiPadCategoryViewController *weakSelf = self;
    [self loadMoreItemsForCategoryInSection:section
                                 completion:^(NSError *error) {
                                     _storyUpdateInProgress = NO;
                                     [self setProgress:NO];
                                     _loadingMoreStories = NO;
                                     MITNewsiPadCategoryViewController *strongSelf = weakSelf;
                                     if (!strongSelf) {
                                         return;
                                     }
                                     
                                     if (error) {
                                         DDLogWarn(@"failed to get more stories from datasource %@",strongSelf.dataSource);
                                         if (error.code == NSURLErrorNotConnectedToInternet) {
                                             [self setError:@"No Internet Connection"];
                                         } else {
                                             [self setError:@"Failed..."];
                                         }
                                         [strongSelf updateLoadingCell];
                                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
                                         dispatch_after(popTime, dispatch_get_main_queue(), ^{
                                             [strongSelf updateLoadingCell];
                                         });
                                     } else {
                                         DDLogVerbose(@"retrieved more stores from datasource %@",strongSelf.dataSource);
                                         //If addOperationWithBlock not here it will not reload immediately ..it will take a few seconds
                                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                             [strongSelf reloadData];
                                         }];
                                     }
                                     if (block) {
                                         block(error);
                                     }
                                 }];
}

- (void)setError:(NSString *)message
{
    if (self.activeViewController == self.gridViewController) {
        [self.gridViewController setError:message];
    } else if (self.activeViewController == self.listViewController) {
        [self.listViewController setError:message];
    }
}

- (void)setProgress:(BOOL)progress
{
    if (self.activeViewController == self.gridViewController) {
        [self.gridViewController setProgress:progress];
    } else if (self.activeViewController == self.listViewController) {
        [self.listViewController setProgress:progress];
    }
}

#pragma mark Refresh Control Text
- (void)updateRefreshStatusWithLastUpdatedTime
{
    if (self.dataSource.refreshedAt) {
        NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.dataSource.refreshedAt
                                                                            toDate:[NSDate date]];
        NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
        [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:updateText]];
    }
}

- (void)updateRefreshStatusWithText:(NSString *)refreshText
{
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:refreshText]];
}

- (void)intervalUpdate
{
    if (self.dataSource.refreshedAt) {
        NSDateComponents *dateDiff = [[NSCalendar currentCalendar] components:NSSecondCalendarUnit
                                                                     fromDate:self.dataSource.refreshedAt
                                                                       toDate:[NSDate date]
                                                                      options:0];
        NSInteger minutes = ([dateDiff second] / 60);
        if (minutes >= 5) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.refreshControl beginRefreshing];
                }];
            [self reloadViewItems:self.refreshControl];
        }
    }
}

- (void)dealloc
{
    if (self.dataSourceDidEndUpdatingToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.dataSourceDidEndUpdatingToken];
    }
}

@end

@implementation MITNewsiPadCategoryViewController (NewsDataSource)
- (MITNewsDataSource*)dataSourceForCategoryInSection:(NSUInteger)section
{
    return self.dataSource;
}

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController
{
    return ([self.dataSource.objects count] ? 1 : 0);
}

- (NSString*)viewController:(UIViewController*)viewController titleForCategoryInSection:(NSUInteger)section
{
    return nil;
}

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    return [self.dataSource.objects count];
}

- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    if ([dataSource.objects count ] > index) {
        return dataSource.objects[index];
    } else {
        return nil;
    }
}
@end

@implementation MITNewsiPadCategoryViewController (NewsDelegate)

#pragma mark MITNewsStoryDetailPagingDelegate
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryInSection:(NSUInteger)index;
{
    return nil;
}

- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section;
{
    MITNewsStory *story = [self viewController:self storyAtIndex:index forCategoryInSection:section];
    if (story) {
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
            
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
            storyDetailViewController.delegate = self;
            MITNewsStory *story = [self viewController:self storyAtIndex:indexPath.row forCategoryInSection:indexPath.section];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
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
    if (_storyUpdateInProgress) {
        if (block) {
            block(nil, nil);
        }
        return;
    }
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    MITNewsDataSource *dataSource = self.dataSource;
    
    NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
    if (currentIndex == NSNotFound) {
        if (block) {
            block(nil, nil);
        }
        return;
    }
    if (currentIndex + 1 < [dataSource.objects count]) {
        if (block) {
            block(dataSource.objects[currentIndex + 1], nil);
        }
    } else {
        
        [self getMoreStoriesForSection:0 completion:^(NSError *error) {
            if (error) {
                block(nil, error);
            } else {
                NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
                
                if (currentIndex + 1 < [dataSource.objects count]) {
                    if (block) {
                        block(dataSource.objects[currentIndex + 1], nil);
                    }
                } else {
                    if (block) {
                        block(nil, nil);
                    }
                }
            }
        }];
    }
}
@end
