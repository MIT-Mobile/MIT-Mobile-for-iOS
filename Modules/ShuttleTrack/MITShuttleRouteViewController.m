#import "MITShuttleRouteViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopCell.h"
#import "MITShuttleRouteStatusCell.h"
#import "MITShuttleController.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"
#import "UITableView+MITAdditions.h"
#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttlePredictionLoader.h"
#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"


static const NSInteger kEmbeddedMapPlaceholderCellRow = 0;

static const CGFloat kEmbeddedMapPlaceholderCellEstimatedHeight = 190.0;
static const CGFloat kRouteStatusCellEstimatedHeight = 80.0;
static const CGFloat kStopCellHeight = 45.0;

static NSString * const kMITShuttleRouteStatusCellNibName = @"MITShuttleRouteStatusCell";

@interface MITShuttleRouteViewController ()

@property (strong, nonatomic) UITableViewCell *embeddedMapPlaceholderCell;
@property (strong, nonatomic) MITShuttleRouteStatusCell *routeStatusCell;
@property (strong, nonatomic) NSTimer *routeRefreshTimer;

@property (nonatomic) BOOL isUpdating;


@end

@implementation MITShuttleRouteViewController

#pragma mark - Init

- (instancetype)initWithRoute:(MITShuttleRoute *)route
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _route = route;
    }
    return self;
}

#pragma mark - Route Setter

- (void)setRoute:(MITShuttleRoute *)route
{
    _route = route;
    [self configureViewForCurrentRoute];
    [self.tableView reloadData];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureViewForCurrentRoute];
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[MITShuttlePredictionLoader sharedLoader] addPredictionDependencyForRoute:self.route];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(predictionsWillUpdate) name:kMITShuttlePredictionLoaderWillUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(predictionsDidUpdate) name:kMITShuttlePredictionLoaderDidUpdateNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMITShuttlePredictionLoaderWillUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMITShuttlePredictionLoaderDidUpdateNotification object:nil];
    [[MITShuttlePredictionLoader sharedLoader] removePredictionDependencyForRoute:self.route];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)configureViewForCurrentRoute
{
    self.title = self.route.title;
    self.routeStatusCell = nil;
}

- (void)setupTableView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleStopCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, self.tableView.frame.size.width, 0, 0);
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

#pragma mark - Update Data

- (void)predictionsWillUpdate
{
    self.isUpdating = YES;
}

- (void)predictionsDidUpdate
{
    self.isUpdating = NO;
    if (!self.shouldSuppressPredictionRefreshReloads) {
        [self.tableView reloadDataAndMaintainSelection];
    }
}

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self predictionsWillUpdate];
    [[MITShuttleController sharedController] getPredictionsForRoute:self.route completion:^(NSArray *predictionLists, NSError *error) {
        [self.refreshControl endRefreshing];
        [self predictionsDidUpdate];
    }];
}

#pragma mark - Stop Highlighting

- (void)highlightStop:(MITShuttleStop *)stop
{
    if (stop) {
        [self.tableView selectRowAtIndexPath:[self indexPathForStop:stop] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    } else {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark - Embedded Map Placeholder Cell

- (UITableViewCell *)embeddedMapPlaceholderCell
{
    if (!_embeddedMapPlaceholderCell) {
        _embeddedMapPlaceholderCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        _embeddedMapPlaceholderCell.backgroundColor = [UIColor clearColor];
        _embeddedMapPlaceholderCell.textLabel.text = nil;
        _embeddedMapPlaceholderCell.separatorInset = UIEdgeInsetsMake(0, _embeddedMapPlaceholderCell.frame.size.width, 0, 0);
        _embeddedMapPlaceholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return _embeddedMapPlaceholderCell;
}

#pragma mark - Route Status Cell

- (MITShuttleRouteStatusCell *)routeStatusCell
{
    if (!_routeStatusCell) {
        _routeStatusCell = [[NSBundle mainBundle] loadNibNamed:kMITShuttleRouteStatusCellNibName owner:self options:nil][0];
        [_routeStatusCell setRoute:self.route];
        
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat width = CGRectGetWidth(screenRect);
        CGFloat height = CGRectGetHeight(screenRect);
        CGFloat longestEdge = height > width ? height : width;
        _routeStatusCell.separatorInset = UIEdgeInsetsMake(0, longestEdge, 0, 0);
    }
    return _routeStatusCell;
}

#pragma mark - UITableViewDataSource Helpers

- (NSInteger)headerCellCount
{
    return [self.dataSource isMapEmbeddedInRouteViewController:self] ? 2 : 1;
}

- (NSInteger)rowIndexForRouteStatusCell
{
    return [self.dataSource isMapEmbeddedInRouteViewController:self] ? 1 : 0;
}

- (NSIndexPath *)indexPathForStop:(MITShuttleStop *)stop
{
    NSInteger stopIndex = [self.route.stops indexOfObject:stop];
    return [NSIndexPath indexPathForRow:stopIndex + [self headerCellCount] inSection:0];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.route.stops count] + [self headerCellCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource isMapEmbeddedInRouteViewController:self] && indexPath.row == kEmbeddedMapPlaceholderCellRow) {
        return self.embeddedMapPlaceholderCell;
    } else if (indexPath.row == [self rowIndexForRouteStatusCell]) {
        return self.routeStatusCell;
    } else {
        MITShuttleStopCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopCellIdentifier forIndexPath:indexPath];
        NSInteger stopIndex = indexPath.row - [self headerCellCount];
        MITShuttleStop *stop = self.route.stops[stopIndex];
        MITShuttleRouteStatus routeStatus = self.route.status;
        if (routeStatus != MITShuttleRouteStatusUnknown && [stop.predictionList.updatedTime timeIntervalSinceNow] >= -60) { // Make sure predictions are 60 seconds old or newer
#warning Add next prediction support and uncomment these
            MITShuttlePrediction *prediction;
//            prediction = [stop nextPrediction];
            [cell setStop:stop prediction:prediction];
//            [cell setIsNextStop:(routeStatus == MITShuttleRouteStatusInService && [self.route isNextStop:stop])];
        } else {
            [cell setStop:stop prediction:nil];
            [cell setIsNextStop:NO];
        }
        [cell setCellType:MITShuttleStopCellTypeRouteDetail];
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource isMapEmbeddedInRouteViewController:self] && indexPath.row == kEmbeddedMapPlaceholderCellRow) {
        return [self.dataSource embeddedMapHeightForRouteViewController:self];
    } else if (indexPath.row == [self rowIndexForRouteStatusCell]) {
        CGFloat height = [self.routeStatusCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        ++height;   // add pt for cell separator;
        return height;
    } else {
        return kStopCellHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource isMapEmbeddedInRouteViewController:self] && indexPath.row == kEmbeddedMapPlaceholderCellRow) {
        return kEmbeddedMapPlaceholderCellEstimatedHeight;
    } else if (indexPath.row == [self rowIndexForRouteStatusCell]) {
        return kRouteStatusCellEstimatedHeight;
    } else {
        return kStopCellHeight;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != [self rowIndexForRouteStatusCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if ([self.dataSource isMapEmbeddedInRouteViewController:self] && indexPath.row == kEmbeddedMapPlaceholderCellRow) {
        if ([self.delegate respondsToSelector:@selector(routeViewControllerDidSelectMapPlaceholderCell:)]) {
            [self.delegate routeViewControllerDidSelectMapPlaceholderCell:self];
        }
    } else if ([self.delegate respondsToSelector:@selector(routeViewController:didSelectStop:)]) {
        NSInteger stopIndex = indexPath.row - [self headerCellCount];
        MITShuttleStop *stop = self.route.stops[stopIndex];
        [self.delegate routeViewController:self didSelectStop:stop];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(routeViewController:didScrollToContentOffset:)]) {
        [self.delegate routeViewController:self didScrollToContentOffset:scrollView.contentOffset];
    }
}

@end
