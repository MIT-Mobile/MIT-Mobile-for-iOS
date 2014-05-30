#import "MITShuttleRouteViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopCell.h"
#import "MITShuttleRouteStatusCell.h"
#import "MITShuttleController.h"

static const NSTimeInterval kRouteRefreshInterval = 10.0;

static const NSInteger kEmbeddedMapPlaceholderCellRow = 0;

static const CGFloat kEmbeddedMapPlaceholderCellEstimatedHeight = 190.0;
static const CGFloat kRouteStatusCellEstimatedHeight = 80.0;
static const CGFloat kStopCellHeight = 45.0;

static NSString * const kMITShuttleRouteStatusCellNibName = @"MITShuttleRouteStatusCell";

@interface MITShuttleRouteViewController ()

@property (strong, nonatomic) UITableViewCell *embeddedMapPlaceholderCell;
@property (strong, nonatomic) MITShuttleRouteStatusCell *routeStatusCell;
@property (strong, nonatomic) NSTimer *routeRefreshTimer;

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

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startRefreshingRoute];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopRefreshingRoute];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupTableView
{
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleStopCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, self.tableView.frame.size.width, 0, 0);
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self stopRefreshingRoute];
    [self startRefreshingRoute];
}

#pragma mark - Data Refresh Timers

- (void)startRefreshingRoute
{
    [self loadRoute];
    NSTimer *routeRefreshTimer = [NSTimer timerWithTimeInterval:kRouteRefreshInterval
                                                               target:self
                                                             selector:@selector(loadRoute)
                                                             userInfo:nil
                                                              repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:routeRefreshTimer forMode:NSRunLoopCommonModes];
    self.routeRefreshTimer = routeRefreshTimer;
}

- (void)stopRefreshingRoute
{
    [self.routeRefreshTimer invalidate];
}

#pragma mark - Load Route

- (void)loadRoute
{
    [self beginRefreshing];
    [[MITShuttleController sharedController] getRouteDetail:self.route completion:^(MITShuttleRoute *route, NSError *error) {
        [self endRefreshing];
        [self.tableView reloadData];
    }];
}

- (void)beginRefreshing
{
    [self.refreshControl beginRefreshing];
    if ([self.delegate respondsToSelector:@selector(routeViewControllerDidBeginRefreshing:)]) {
        [self.delegate routeViewControllerDidBeginRefreshing:self];
    }
}

- (void)endRefreshing
{
    [self.refreshControl endRefreshing];
    if ([self.delegate respondsToSelector:@selector(routeViewControllerDidEndRefreshing:)]) {
        [self.delegate routeViewControllerDidEndRefreshing:self];
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
        MITShuttlePrediction *prediction = [stop nextPredictionForRoute:self.route];
        [cell setStop:stop prediction:prediction];
        [cell setIsNextStop:(self.route.status == MITShuttleRouteStatusInService && [self.route isNextStop:stop])];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
