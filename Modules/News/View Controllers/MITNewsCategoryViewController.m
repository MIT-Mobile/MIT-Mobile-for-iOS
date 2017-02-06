#import "MITNewsCategoryViewController.h"
#import "MITCoreData.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsConstants.h"
#import "MITAdditions.h"

@interface MITNewsCategoryViewController ()

@property (nonatomic) BOOL movingBackFromStory;
@property (nonatomic) BOOL isSingleDataSource;
@property (nonatomic, copy) NSArray *dataSources;
@property (strong) id dataSourceDidEndUpdatingToken;
@property (nonatomic) BOOL storyUpdateInProgress;
@property (nonatomic) BOOL loadingMoreStories;
@end

@implementation MITNewsCategoryViewController

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
    self.isSingleDataSource = YES;
    [super viewDidLoad];
    
    self.showsFeaturedStories = NO;
    self.dataSources = @[self.dataSource];
    self.lastUpdated = self.dataSource.refreshedAt;
    if (self.previousPresentationStyle == MITNewsPresentationStyleList) {
        self.presentationStyle = MITNewsPresentationStyleList;
        self.listViewController.isACategoryView = YES;
    } else {
        self.presentationStyle = MITNewsPresentationStyleGrid;
        self.gridViewController.showSingleCategory = YES;
    }
    self.previousPresentationStyle = self.presentationStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.dataSource.isUpdating) {
        self.storyUpdateInProgress = YES;
    }
    
    [super viewWillAppear:animated];

    if (self.dataSource.isUpdating) {
        [self setupFinishedUpdateNotification];
    }

    [self updateNavigationItem:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.movingBackFromStory) {
        [self intervalUpdate];
        self.movingBackFromStory = YES;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!self.refreshControl.refreshing) {
            [self.refreshControl beginRefreshing];
            [self.refreshControl endRefreshing];
        }
    }];
}

#pragma mark Datasource Notification
- (void)setupFinishedUpdateNotification
{
    __weak MITNewsCategoryViewController *weakSelf = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    void (^notificationBlock)(NSNotification*) = ^(NSNotification *note) {
        MITNewsCategoryViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.storyUpdateInProgress = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.dataSourceDidEndUpdatingToken
                                                        name:MITNewsDataSourceDidEndUpdatingNotification
                                                      object:strongSelf.dataSource];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MITNewsRefreshControlHangTime * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [strongSelf.refreshControl endRefreshing];
        });
        if (strongSelf.dataSource.refreshedAt) {
            strongSelf.lastUpdated = strongSelf.dataSource.refreshedAt;
            [strongSelf updateRefreshStatusWithLastUpdatedTime];
        }
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
    [super getMoreStoriesForSection:section completion:nil];
}

- (void)intervalUpdate
{
    if (!self.dataSource.refreshedAt || self.dataSource.isUpdating || self.storyUpdateInProgress || self.loadingMoreStories) {
        return;
    }
    NSDateComponents *dateDiff = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond
                                                                 fromDate:self.dataSource.refreshedAt
                                                                   toDate:[NSDate date]
                                                                  options:0];
    NSInteger minutes = ([dateDiff second] / 60);
    if (minutes >= 5) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.refreshControl beginRefreshing];
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void){
                [self showRefreshControl];
                
            } completion:nil];
        }];
        [self updateRefreshStatusWithText:@"Updating..."];
        [self reloadViewItems:self.refreshControl];
    }
}

- (void)dealloc
{
    if (self.dataSourceDidEndUpdatingToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.dataSourceDidEndUpdatingToken];
    }
}
@end
