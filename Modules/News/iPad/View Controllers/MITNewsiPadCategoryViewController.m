#import "MITNewsiPadCategoryViewController.h"
#import "MITCoreData.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsConstants.h"
#import "MITAdditions.h"

@interface MITNewsiPadCategoryViewController (NewsDataSource) <MITNewsStoryDataSource>
@end

@interface MITNewsiPadCategoryViewController ()

@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic) BOOL movingBackFromStory;
@property (nonatomic) BOOL category;
@property (nonatomic, copy) NSArray *dataSources;

@property(strong) id dataSourceDidEndUpdatingToken;
@end

@implementation MITNewsiPadCategoryViewController {
    BOOL _isTransitioningToPresentationStyle;
    BOOL _storyUpdateInProgress;
    BOOL _loadingMoreStories;
}

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
    self.dataSources = @[self.dataSource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.category = YES;
    self.lastUpdated = self.dataSource.refreshedAt;
    [super viewWillAppear:animated];
    
    if (self.previousPresentationStyle) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid] && self.previousPresentationStyle == MITNewsPresentationStyleGrid) {
            [self setPresentationStyle:MITNewsPresentationStyleGrid animated:animated];
            self.gridViewController.isCategory = YES;
        } else {
            [self setPresentationStyle:MITNewsPresentationStyleList animated:animated];
            self.listViewController.isCategory = YES;
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
                                 self.lastUpdated = [NSDate date];
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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.refreshControl beginRefreshing];
            [self.refreshControl endRefreshing];
        }];
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
        [self setPresentationStyle:self.presentationStyle animated:YES];
        [self updateNavigationItem:YES];
    }
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    if (!_storyUpdateInProgress) {
        self.presentationStyle = MITNewsPresentationStyleList;
        [self setPresentationStyle:self.presentationStyle animated:YES];
        [self updateNavigationItem:YES];
    }
}

#pragma mark Utility Methods
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
