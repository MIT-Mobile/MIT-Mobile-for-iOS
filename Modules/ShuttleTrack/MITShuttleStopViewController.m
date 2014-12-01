#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleController.h"
#import "MITShuttleVehicleList.h"
#import "NSDateFormatter+RelativeString.h"
#import "MITShuttleStopNotificationManager.h"
#import "MITShuttleStopPredictionLoader.h"
#import "MITShuttleRouteCell.h"
#import "MITShuttleRouteContainerViewController.h"

NSString * const kMITShuttleStopViewControllerAlarmCellReuseIdentifier = @"kMITShuttleStopViewControllerAlarmCellReuseIdentifier";
NSString * const kMITShuttleStopViewControllerRouteCellReuseIdentifier = @"kMITShuttleStopViewControllerRouteCellReuseIdentifier";
NSString * const kMITShuttleStopViewControllerDefaultCellReuseIdentifier = @"kMITShuttleStopViewControllerDefaultCellReuseIdentifier";

@interface MITShuttleStopViewController () <MITShuttleStopPredictionLoaderDelegate, MITShuttleStopAlarmCellDelegate>

@property (nonatomic, strong) NSArray *intersectingRoutes;
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
        [self refreshIntersectingRoutes];
        
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

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self.predictionLoader startRefreshingPredictions];
    [self.predictionLoader stopRefreshingPredictions];
}

#pragma mark - Refreshing

- (void)beginRefreshing
{
    [self.refreshControl beginRefreshing];
}

- (void)endRefreshing
{
    [self.refreshControl endRefreshing];
    self.lastUpdatedDate = [NSDate date];
    [self.tableView reloadData];
}

#pragma mark - Private Methods

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleStopAlarmCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITShuttleStopViewControllerDefaultCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleRouteCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerRouteCellReuseIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)setupPredictionLoader
{
    MITShuttleStopPredictionLoader *predictionLoader = [[MITShuttleStopPredictionLoader alloc] initWithStop:self.stop];
    predictionLoader.delegate = self;
    self.predictionLoader = predictionLoader;
}

- (void)refreshIntersectingRoutes
{
    NSMutableOrderedSet *mutableRoutes = [self.stop.routes mutableCopy];
    if (self.route) {
        NSInteger index = [mutableRoutes indexOfObject:self.route];
        if (index < mutableRoutes.count) {
            [mutableRoutes removeObjectAtIndex:index];
        }
    }
    self.intersectingRoutes = [mutableRoutes array];
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
        case MITShuttleStopViewOptionAll:
            return 2;
        case MITShuttleStopViewOptionIntersectingOnly:
            return 1;
        default:
            return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll:
            switch (section) {
                case 0: {
                    NSArray *predictionsForRoute = self.predictionLoader.predictionsByRoute[self.route.identifier];
                    return predictionsForRoute.count > 0 ? predictionsForRoute.count : 1;
                }
                case 1: {
                    return self.intersectingRoutes.count > 0 ? self.intersectingRoutes.count : 1;
                }
                default: {
                    return 0;
                }
            }
        case MITShuttleStopViewOptionIntersectingOnly:
            return self.intersectingRoutes.count > 0 ? self.intersectingRoutes.count : 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll: {
            switch (indexPath.section) {
                case 0: {
                    return [self selectedRoutePredictionCellAtIndexPath:indexPath];
                }
                case 1: {
                    return [self intersectingRouteCellAtIndexPath:indexPath];
                }
                default: {
                    return [UITableViewCell new];
                }
            }
        }
        case MITShuttleStopViewOptionIntersectingOnly: {
            return [self intersectingRouteCellAtIndexPath:indexPath];
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

#pragma mark - UITableViewDataSource Helpers

- (UITableViewCell *)selectedRoutePredictionCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[self.route.identifier];
    MITShuttlePrediction *prediction = nil;
    
    if (!predictionsArray) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerDefaultCellReuseIdentifier forIndexPath:indexPath];
        cell.textLabel.text = @"No current predictions";
        return cell;
    } else {
        MITShuttleStopAlarmCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        prediction = predictionsArray[indexPath.row];
        [cell updateUIWithPrediction:prediction];
        return cell;
    }
}

- (UITableViewCell *)intersectingRouteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.intersectingRoutes.count < 1) {
        UITableViewCell *noIntersectionsCell = [self.tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerDefaultCellReuseIdentifier forIndexPath:indexPath];
        noIntersectionsCell.textLabel.text = @"No intersecting routes";
        return noIntersectionsCell;
    }
    
    MITShuttleRouteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerRouteCellReuseIdentifier forIndexPath:indexPath];
    MITShuttleRoute *route = self.intersectingRoutes[indexPath.row];
    [cell setRoute:route];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll: {
            switch (section) {
                case 0: {
                    return @" ";
                }
                case 1: {
                    return @"INTERSECTING ROUTES";
                }
                default: {
                    return nil;
                }
            }
        }
        case MITShuttleStopViewOptionIntersectingOnly: {
            return nil;
        }
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll: {
            switch (section) {
                case 0: {
                    NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[self.route.identifier];
                    if (predictionsArray) {
                        return @"Tap bell to be notified 5 minutes before arrival.";
                    } else {
                        return nil;
                    }
                }
                case 1: {
                    return @"Other routes stopping at or near this stop.";
                }
                default: {
                    return nil;
                }
            }
        }
        case MITShuttleStopViewOptionIntersectingOnly: {
            return @"Other routes stopping at or near this stop.";
        }
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll: {
            if (indexPath.section == 1) {
                MITShuttleRouteContainerViewController *routeVC = [[MITShuttleRouteContainerViewController alloc] initWithRoute:self.intersectingRoutes[indexPath.row] stop:nil];
                [self.navigationController pushViewController:routeVC animated:YES];
            }
            break;
        }
        case MITShuttleStopViewOptionIntersectingOnly: {
            MITShuttleRouteContainerViewController *routeVC = [[MITShuttleRouteContainerViewController alloc] initWithRoute:self.intersectingRoutes[indexPath.row] stop:nil];
            [self.navigationController pushViewController:routeVC animated:YES];
            break;
        }
    }
}

#pragma mark - MITShuttleStopAlarmCellDelegate

- (void)stopAlarmCellDidToggleAlarm:(MITShuttleStopAlarmCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[self.route.identifier];
    MITShuttlePrediction *prediction = predictionsArray[indexPath.row];
    
    [[MITShuttleStopNotificationManager sharedManager] toggleNotifcationForPrediction:prediction];
    
    [cell updateNotificationButtonWithPrediction:prediction];
}

@end
