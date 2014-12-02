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

typedef NS_ENUM(NSUInteger, MITShuttleStopViewControllerSectionType) {
    MITShuttleStopViewControllerSectionTypeTitle,
    MITShuttleStopViewControllerSectionTypePredictions,
    MITShuttleStopViewControllerSectionTypeRoutes
};

@interface MITShuttleStopViewController () <MITShuttleStopPredictionLoaderDelegate, MITShuttleStopAlarmCellDelegate>

@property (nonatomic, strong) NSArray *intersectingRoutes;
@property (nonatomic, strong) NSArray *vehicles;
@property (nonatomic, strong) UILabel *helpLabel;
@property (nonatomic, strong) UILabel *statusFooterLabel;
@property (nonatomic, strong) NSDate *lastUpdatedDate;

@property (nonatomic, strong) NSArray *sectionTypes;

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
        _shouldHideFooter = NO;
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
    [self configureTableSections];
    [self.tableView reloadData];
}

#pragma mark - Content Height

// Returns an estimated preferred height for the table, or 0 if no such height exists.
- (CGFloat)preferredContentHeight
{
    if (self.viewOption == MITShuttleStopViewOptionAll) {
        return 0;
    }
    CGFloat rowHeight = 44; // TODO: Shouldn't hard-code this
    NSInteger numberOfRows = MAX(1, self.intersectingRoutes.count);
    if (self.tableTitle) {
        numberOfRows++;
    }
    return numberOfRows * rowHeight;
}

- (void)setFixedContentSize:(CGSize)size
{
    NSDictionary *views = @{@"tableView": self.tableView};
    NSDictionary *metrics = @{@"width": @(size.width),
                              @"height": @(size.height)};
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[tableView(width)]" options:0 metrics:metrics views:views]];
    [self.tableView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[tableView(height)]" options:0 metrics:metrics views:views]];
}

#pragma mark - Private Methods

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleStopAlarmCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITShuttleStopViewControllerDefaultCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleRouteCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerRouteCellReuseIdentifier];
    
    [self configureTableSections];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)configureTableSections
{
    NSMutableArray *sectionTypes = [[NSMutableArray alloc] init];
    if (self.tableTitle) {
        [sectionTypes addObject:@(MITShuttleStopViewControllerSectionTypeTitle)];
    }
    if (self.viewOption == MITShuttleStopViewOptionAll) {
        [sectionTypes addObject:@(MITShuttleStopViewControllerSectionTypePredictions)];
    }
    [sectionTypes addObject:@(MITShuttleStopViewControllerSectionTypeRoutes)];
    self.sectionTypes = [sectionTypes copy];
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
    if (self.viewOption == MITShuttleStopViewOptionAll) {
        [self beginRefreshing];
    }
}

- (void)stopPredictionLoaderDidReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    if (self.viewOption == MITShuttleStopViewOptionAll) {
        [self endRefreshing];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionTypes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MITShuttleStopViewControllerSectionType sectionType = [[self.sectionTypes objectAtIndex:section] integerValue];
    switch (sectionType) {
        case MITShuttleStopViewControllerSectionTypeTitle: {
            return 1;
        }
        case MITShuttleStopViewControllerSectionTypePredictions: {
            NSArray *predictionsForRoute = self.predictionLoader.predictionsByRoute[self.route.identifier];
            return predictionsForRoute.count > 0 ? predictionsForRoute.count : 1;
        }
        case MITShuttleStopViewControllerSectionTypeRoutes: {
            return self.intersectingRoutes.count > 0 ? self.intersectingRoutes.count : 1;
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleStopViewControllerSectionType sectionType = [[self.sectionTypes objectAtIndex:indexPath.section] integerValue];
    switch (sectionType) {
        case MITShuttleStopViewControllerSectionTypeTitle: {
            return [self tableTitleCellForIndexPath:indexPath];
        }
        case MITShuttleStopViewControllerSectionTypePredictions: {
            return [self selectedRoutePredictionCellAtIndexPath:indexPath];
        }
        case MITShuttleStopViewControllerSectionTypeRoutes: {
            return [self intersectingRouteCellAtIndexPath:indexPath];
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

#pragma mark - UITableViewDataSource Helpers

- (UITableViewCell *)tableTitleCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerDefaultCellReuseIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.tableTitle;
    return cell;
}

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
    MITShuttleStopViewControllerSectionType sectionType = [[self.sectionTypes objectAtIndex:section] integerValue];
    switch (self.viewOption) {
        case MITShuttleStopViewOptionAll: {
            switch (sectionType) {
                case MITShuttleStopViewControllerSectionTypeTitle: {
                    return @" ";
                }
                case MITShuttleStopViewControllerSectionTypePredictions: {
                    return @" ";
                }
                case MITShuttleStopViewControllerSectionTypeRoutes: {
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
    if (self.shouldHideFooter) {
        return nil;
    }
    
    MITShuttleStopViewControllerSectionType sectionType = [[self.sectionTypes objectAtIndex:section] integerValue];
    switch (sectionType) {
        case MITShuttleStopViewControllerSectionTypeTitle: {
            return @" ";
        }
        case MITShuttleStopViewControllerSectionTypePredictions: {
            NSArray *predictionsArray = self.predictionLoader.predictionsByRoute[self.route.identifier];
            if (predictionsArray) {
                return @"Tap bell to be notified 5 minutes before arrival.";
            } else {
                return nil;
            }
        }
        case MITShuttleStopViewControllerSectionTypeRoutes: {
            return @"Other routes stopping at or near this stop.";
        }
        default: {
            return nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleStopViewControllerSectionType sectionType = [[self.sectionTypes objectAtIndex:indexPath.section] integerValue];
    if (sectionType == MITShuttleStopViewControllerSectionTypeRoutes) {
        MITShuttleRoute *route = self.intersectingRoutes[indexPath.row];
        if ([self.delegate respondsToSelector:@selector(shuttleStopViewController:didSelectRoute:)]) {
            [self.delegate shuttleStopViewController:self didSelectRoute:route];
        } else {
            // Default behavior
            MITShuttleRouteContainerViewController *routeVC = [[MITShuttleRouteContainerViewController alloc] initWithRoute:route stop:nil];
            [self.navigationController pushViewController:routeVC animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
