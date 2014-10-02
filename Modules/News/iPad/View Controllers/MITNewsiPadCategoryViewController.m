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
    self.category = YES;
    self.lastUpdated = self.dataSource.refreshedAt;
    if (self.previousPresentationStyle == MITNewsPresentationStyleList) {
        self.presentationStyle = MITNewsPresentationStyleList;
        self.listViewController.isCategory = YES;
    } else {
        self.presentationStyle = MITNewsPresentationStyleGrid;
        self.gridViewController.isCategory = YES;
    }
    self.previousPresentationStyle = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateNavigationItem:YES];
    if (self.dataSource.isUpdating || !self.lastUpdated) {
        [self setupFinishedUpdateNotification];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.movingBackFromStory) {
        [self intervalUpdate];
        self.movingBackFromStory = YES;
    }
    
    if (!self.refreshControl.refreshing) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.refreshControl beginRefreshing];
            [self.refreshControl endRefreshing];
        }];
    }
}

- (void)updateLoadingCell
{
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        [self.gridViewController.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]]];
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        [self.listViewController.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource.objects count] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark Datasource Notification
- (void)setupFinishedUpdateNotification
{
    __weak MITNewsiPadCategoryViewController *weakSelf = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    void (^notificationBlock)(NSNotification*) = ^(NSNotification *note) {
        MITNewsiPadCategoryViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.dataSourceDidEndUpdatingToken
                                                        name:MITNewsDataSourceDidEndUpdatingNotification
                                                      object:strongSelf.dataSource];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [strongSelf.refreshControl endRefreshing];
        });
        self.lastUpdated = [NSDate date];
        [strongSelf updateRefreshStatusWithLastUpdatedTime];
    };
    
    
    self.dataSourceDidEndUpdatingToken = [center addObserverForName:MITNewsDataSourceDidEndUpdatingNotification
                                                             object:self.dataSource
                                                              queue:nil
                                                         usingBlock:notificationBlock];
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
    if (!self.dataSource.refreshedAt || self.dataSource.isUpdating || self.storyUpdateInProgress || self.loadingMoreStories) {
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
        [self updateRefreshStatusWithText:@"Updating..."];
        [self reloadViewItems:self.refreshControl];
    }
}

#pragma mark setters
- (void)setError:(NSString *)message
{
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        self.gridViewController.errorMessage = message;
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        self.listViewController.errorMessage = message;
    }
}

- (void)setProgress:(BOOL)progress
{
    if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        self.gridViewController.storyUpdateInProgress = progress;
    } else if (self.presentationStyle == MITNewsPresentationStyleList) {
        self.listViewController.storyUpdateInProgress = progress;
    }
}

- (void)dealloc
{
    if (self.dataSourceDidEndUpdatingToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.dataSourceDidEndUpdatingToken];
    }
}
@end
