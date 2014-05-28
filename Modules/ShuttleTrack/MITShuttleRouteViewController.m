#import "MITShuttleRouteViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopCell.h"
#import "MITShuttleRouteStatusCell.h"

static const NSInteger kRouteStatusCellRow = 0;
static const NSInteger kRouteStatusCellCount = 1;

static const CGFloat kRouteStatusCellEstimatedHeight = 60.0;
static const CGFloat kStopCellHeight = 45.0;

static NSString * const kMITShuttleRouteStatusCellNibName = @"MITShuttleRouteStatusCell";

@interface MITShuttleRouteViewController ()

@property (strong, nonatomic) MITShuttleRouteStatusCell *routeStatusCell;

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

- (MITShuttleRouteStatusCell *)routeStatusCell
{
    if (!_routeStatusCell) {
        _routeStatusCell = [[NSBundle mainBundle] loadNibNamed:kMITShuttleRouteStatusCellNibName owner:self options:nil][0];
        [_routeStatusCell setRoute:self.route];
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
        NSInteger stopIndex = indexPath.row - 1;
        MITShuttleStop *stop = self.route.stops[stopIndex];
        [cell setStop:stop prediction:nil];
        [cell setCellType:MITShuttleStopCellTypeRouteDetail];
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kRouteStatusCellRow) {
        CGFloat height = [self.routeStatusCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        ++height;   // add pt for cell separator;
        return height;
    } else {
        return kStopCellHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kRouteStatusCellRow) {
        return kRouteStatusCellEstimatedHeight;
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
