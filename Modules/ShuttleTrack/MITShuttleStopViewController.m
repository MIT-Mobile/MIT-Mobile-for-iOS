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

@interface MITShuttleStopViewController () <MITShuttleStopPredictionLoaderDelegate>

@property (nonatomic, strong) NSArray *sortedRoutes;
@property (nonatomic, retain) NSArray *vehicles;
@property (nonatomic, retain) UILabel *statusFooterLabel;
@property (nonatomic, strong) NSDate *lastUpdatedDate;

@end

@implementation MITShuttleStopViewController

- (instancetype)initWithStop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route
{
    return [self initWithStop:stop route:route predictionLoader:nil];
}

- (instancetype)initWithStop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route predictionLoader:(MITShuttleStopPredictionLoader *)predictionLoader
{
    self = [super initWithStyle:UITableViewStyleGrouped];
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
    [self.predictionLoader startRefreshingPredictions];
    [self setupHelpAndStatusFooter];
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
    
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 30)];
    helpLabel.font = [UIFont systemFontOfSize:12];
    helpLabel.textColor = [UIColor lightGrayColor];
    helpLabel.textAlignment = NSTextAlignmentCenter;
    helpLabel.text = @"Tap bell to be notified 5 min. before arrival";
    [helpAndStatusFooter addSubview:helpLabel];
    helpLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[helpLabel]" options:0 metrics:nil views:@{@"helpLabel": helpLabel}]];
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[helpLabel]|" options:0 metrics:nil views:@{@"helpLabel": helpLabel}]];
    
    self.statusFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 320, 30)];
    self.statusFooterLabel.font = [UIFont systemFontOfSize:14];
    self.statusFooterLabel.textColor = [UIColor blackColor];
    self.statusFooterLabel.textAlignment = NSTextAlignmentCenter;
    [helpAndStatusFooter addSubview:self.statusFooterLabel];
    self.statusFooterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[statusFooterLabel]" options:0 metrics:nil views:@{@"statusFooterLabel": self.statusFooterLabel}]];
    [helpAndStatusFooter addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[statusFooterLabel]|" options:0 metrics:nil views:@{@"statusFooterLabel": self.statusFooterLabel}]];
    
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
            prediction = predictionsArray[indexPath.row];
            [cell updateUIWithPrediction:prediction atStop:self.stop];
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

@end
