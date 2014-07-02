#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleController.h"
#import "MITShuttleVehicleList.h"
#import "MITShuttleRouteNoDataCell.h"
#import "NSDateFormatter+RelativeString.h"
#import "MITShuttleStopNotificationManager.h"
#import "MITShuttleStopPredictionLoader.h"

NSString * const kMITShuttleStopViewControllerAlarmCellReuseIdentifier = @"kMITShuttleStopViewControllerAlarmCellReuseIdentifier";
NSString * const kMITShuttleStopViewControllerNoDataCellReuseIdentifier = @"kMITShuttleStopViewControllerNoDataCellReuseIdentifier";

@interface MITShuttleStopViewController () <MITShuttleStopPredictionLoaderDelegate, MITShuttleStopAlarmCellDelegate>

@property (nonatomic, strong) NSArray *sortedRoutes;
@property (nonatomic, strong) NSArray *vehicles;
@property (nonatomic, strong) UILabel *helpLabel;
@property (nonatomic, strong) UILabel *statusFooterLabel;
@property (nonatomic, strong) NSDate *lastUpdatedDate;

@end

@implementation MITShuttleStopViewController

- (instancetype)initWithStyle:(UITableViewStyle)style stop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route
{
    return [self initWithStyle:style stop:stop route:route predictionLoader:nil];
}

- (instancetype)initWithStyle:(UITableViewStyle)style stop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route predictionLoader:(MITShuttleStopPredictionLoader *)predictionLoader
{
    self = [super initWithStyle:style];
    if (self) {
        _stop = stop;
        _route = route;
        _predictionLoader = predictionLoader;
        [self refreshSortedRoutes];
        
        // default to using one prediction loader per view controller
        if (!predictionLoader) {
            [self setupPredictionLoader];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupTableView];
    [self setupHelpAndStatusFooter];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.predictionLoader startRefreshingPredictions];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.predictionLoader stopRefreshingPredictions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self.predictionLoader startRefreshingPredictions];
    [self.predictionLoader stopRefreshingPredictions];
}

#pragma mark - Refreshing

- (void)beginRefreshing
{
    [self updateStatusLabel];
    [self.refreshControl beginRefreshing];
}

- (void)endRefreshing
{
    [self.refreshControl endRefreshing];
    self.lastUpdatedDate = [NSDate date];
    [self.tableView reloadData];
    [self updateHelpLabel];
    [self updateStatusLabel];
}

#pragma mark - Private Methods

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleStopAlarmCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleRouteNoDataCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerNoDataCellReuseIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)setupHelpAndStatusFooter
{
    UIView *helpAndStatusFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    
    self.helpLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.helpLabel.font = [UIFont systemFontOfSize:12];
    self.helpLabel.numberOfLines = 0;
    [helpAndStatusFooter addSubview:self.helpLabel];
    self.helpLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[helpLabel]" options:0 metrics:nil views:@{@"helpLabel": self.helpLabel}]];
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=10-[helpLabel]->=10-|" options:0 metrics:nil views:@{@"helpLabel": self.helpLabel}]];
    [helpAndStatusFooter addConstraint:[NSLayoutConstraint constraintWithItem:self.helpLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:helpAndStatusFooter attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.helpLabel.textColor = [UIColor lightGrayColor];
        self.helpLabel.text = @"Tap bell to be notified 5 min. before arrival";
        self.helpLabel.textAlignment = NSTextAlignmentCenter;

        self.statusFooterLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.statusFooterLabel.font = [UIFont systemFontOfSize:14];
        self.statusFooterLabel.textColor = [UIColor blackColor];
        self.statusFooterLabel.textAlignment = NSTextAlignmentCenter;
        self.statusFooterLabel.adjustsFontSizeToFitWidth = YES;
        self.statusFooterLabel.minimumScaleFactor = 0.5;
        [helpAndStatusFooter addSubview:self.statusFooterLabel];
        self.statusFooterLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[statusFooterLabel]" options:0 metrics:nil views:@{@"statusFooterLabel": self.statusFooterLabel}]];
        [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=10-[statusFooterLabel]->=10-|" options:0 metrics:nil views:@{@"statusFooterLabel": self.statusFooterLabel}]];
        [helpAndStatusFooter addConstraint:[NSLayoutConstraint constraintWithItem:self.statusFooterLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:helpAndStatusFooter attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    } else {
        self.helpLabel.textAlignment = NSTextAlignmentLeft;
        self.helpLabel.textColor = [UIColor grayColor];
        self.helpLabel.preferredMaxLayoutWidth = 180.0;
        self.helpLabel.text = @"Tap bell icon to be notified 5 minutes before the estimated arrival time";
        self.helpLabel.hidden = YES;
    }
    
    self.tableView.tableFooterView = helpAndStatusFooter;
}

- (void)setupPredictionLoader
{
    MITShuttleStopPredictionLoader *predictionLoader = [[MITShuttleStopPredictionLoader alloc] initWithStop:self.stop];
    predictionLoader.delegate = self;
    self.predictionLoader = predictionLoader;
}

- (void)refreshSortedRoutes
{
    NSMutableOrderedSet *mutableRoutes = [self.stop.routes mutableCopy];
    if (self.route) {
        NSInteger index = [mutableRoutes indexOfObject:self.route];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [mutableRoutes moveObjectsAtIndexes:indexSet toIndex:0];
    }
    self.sortedRoutes = [mutableRoutes array];
}

- (void)updateHelpLabel
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSArray *predictionsForRoute = self.predictionLoader.predictionsByRoute[self.route.identifier];
        self.helpLabel.hidden = ([predictionsForRoute count] == 0);
    }
}

- (void)updateStatusLabel
{
    if (self.lastUpdatedDate) {
        self.statusFooterLabel.text = [NSString stringWithFormat:@"Updated %@", [NSDateFormatter relativeDateStringFromDate:self.lastUpdatedDate toDate:[NSDate date]]];
    }
}

#pragma mark - MITShuttleStopPredictionLoaderDelegate

- (void)stopPredictionLoaderWillReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    [self beginRefreshing];
}

- (void)stopPredictionLoaderDidReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    [self endRefreshing];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionSingleRoute:
            return 1;
        case MITShuttleStopViewOptionAllRoutes:
            return [self.stop.routes count];
        default:
            return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MITShuttleRoute *route = [self routeForSection:section];
    NSArray *predictionsForRoute = self.predictionLoader.predictionsByRoute[route.identifier];
    return predictionsForRoute.count > 0 ? predictionsForRoute.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleRoute *route = [self routeForSection:indexPath.section];
    
    if (route) {
        NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[route.identifier];
        MITShuttlePrediction *prediction = nil;
        
        if (![route.scheduled boolValue]) {
            MITShuttleRouteNoDataCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerNoDataCellReuseIdentifier forIndexPath:indexPath];
            [cell setNotInService:route];
            return cell;
        } else if (![route.predictable boolValue] || !predictionsArray) {
            MITShuttleRouteNoDataCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerNoDataCellReuseIdentifier forIndexPath:indexPath];
            [cell setNoPredictions:route];
            return cell;
        } else {
            MITShuttleStopAlarmCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            prediction = predictionsArray[indexPath.row];
            [cell updateUIWithPrediction:prediction];
            return cell;
        }
    }
    
    return [UITableViewCell new];
}

#pragma mark - UITableViewDataSource Helpers

- (MITShuttleRoute *)routeForSection:(NSInteger)section
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionSingleRoute:
            return self.route;
        case MITShuttleStopViewOptionAllRoutes:
            return self.sortedRoutes[section];
        default:
            return nil;
    }
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionSingleRoute: {
            return nil;
        }
        case MITShuttleStopViewOptionAllRoutes: {
            MITShuttleRoute *route = [self routeForSection:section];
            return [route.title uppercaseString];
        }
        default:
            return nil;
    }
}

#pragma mark - MITShuttleStopAlarmCellDelegate

- (void)stopAlarmCellDidToggleAlarm:(MITShuttleStopAlarmCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MITShuttleRoute *route = [self routeForSection:indexPath.section];
    NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[route.identifier];
    MITShuttlePrediction *prediction = predictionsArray[indexPath.row];
    
    [[MITShuttleStopNotificationManager sharedManager] toggleNotifcationForPrediction:prediction];
    
    [cell updateNotificationButtonWithPrediction:prediction];
}

@end
