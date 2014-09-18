#import "MITNewsiPadCategoryViewController.h"
#import "MITCoreData.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsConstants.h"
#import "MITAdditions.h"

@interface MITNewsiPadCategoryViewController ()

@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic) BOOL movingBackFromStory;
@property (nonatomic) BOOL category;
@property (nonatomic, copy) NSArray *dataSources;
@property (strong) id dataSourceDidEndUpdatingToken;
@property (nonatomic) BOOL storyUpdateInProgress;
@property (nonatomic) BOOL loadingMoreStories;
@end

@implementation MITNewsiPadCategoryViewController

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
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.showsFeaturedStories = NO;
    self.dataSources = @[self.dataSource];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.category = YES;
    self.lastUpdated = self.dataSource.refreshedAt;
    if (self.previousPresentationStyle == MITNewsPresentationStyleList) {
        self.isCurrentPresentationStyleAList = YES;
        self.listViewController.isCategory = YES;
    } else {
        self.gridViewController.isCategory = YES;
    }
    self.previousPresentationStyle = nil;
    
    [super viewWillAppear:animated];

    [self updateNavigationItem:YES];
    if (self.dataSource.isUpdating) {
        [self setupFinishedUpdateNotification];
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

#pragma mark Datasource Notification
- (void)setupFinishedUpdateNotification
{
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

#pragma mark Story Downloading
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError *))block
{
    if (self.storyUpdateInProgress || self.loadingMoreStories || self.dataSource.isUpdating) {
        if (block) {
            block(nil);
        }
        return;
    }

    [self setProgress:YES];
    [self updateLoadingCell];
    self.loadingMoreStories = YES;
    
    __weak MITNewsiPadCategoryViewController *weakSelf = self;
    [super getMoreStoriesForSection:section completion:^(NSError *error) {
        
        [self setProgress:NO];
        self.loadingMoreStories = NO;
        
        MITNewsiPadCategoryViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (error) {
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

- (void)intervalUpdate
{
    if (!self.dataSource.refreshedAt) {
        return;
    }
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

#pragma mark setters
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

- (void)dealloc
{
    if (self.dataSourceDidEndUpdatingToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.dataSourceDidEndUpdatingToken];
    }
}
@end
