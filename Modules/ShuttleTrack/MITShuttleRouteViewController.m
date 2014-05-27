#import "MITShuttleRouteViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopCell.h"

static const NSInteger kRouteStatusCellRow = 0;
static const NSInteger kRouteStatusCellCount = 1;

static const CGFloat kRouteStatusCellHeight = 60.0;
static const CGFloat kStopCellHeight = 45.0;

@interface MITShuttleRouteViewController ()

@property (strong, nonatomic) UITableViewCell *routeStatusCell;

@end

@implementation MITShuttleRouteViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _route = route;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleStopCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
}

#pragma mark - Route Status Cell

- (UITableViewCell *)routeStatusCell
{
    if (!_routeStatusCell) {
        _routeStatusCell = [[UITableViewCell alloc] init];
    }
    return _routeStatusCell;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.route.stops count] + kRouteStatusCellCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kRouteStatusCellRow) {
        return self.routeStatusCell;
    } else {
        MITShuttleStopCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopCellIdentifier forIndexPath:indexPath];
        [cell setCellType:MITShuttleStopCellTypeRouteDetail];
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kRouteStatusCellRow) {
        return kRouteStatusCellHeight;
    } else {
        return kStopCellHeight;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row != kRouteStatusCellRow);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(routeViewController:didSelectStop:)]) {
        NSInteger stopIndex = indexPath.row - 1;
        MITShuttleStop *stop = self.route.stops[stopIndex];
        [self.delegate routeViewController:self didSelectStop:stop];
    }
}

@end
