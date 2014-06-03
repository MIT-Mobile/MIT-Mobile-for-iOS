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

NSString * const kMITShuttleStopViewControllerAlarmCellReuseIdentifier = @"kMITShuttleStopViewControllerAlarmCellReuseIdentifier";
NSString * const kMITShuttleStopViewControllerNoDataCellReuseIdentifier = @"kMITShuttleStopViewControllerNoDataCellReuseIdentifier";

static const NSTimeInterval kStopRefreshInterval = 10.0;

@interface MITShuttleStopViewController ()

@property (nonatomic, retain) NSDictionary *predictionsByRoute;
@property (nonatomic, retain) NSArray *vehicles;
@property (nonatomic, retain) UILabel *statusFooterLabel;
@property (strong, nonatomic) NSTimer *stopRefreshTimer;
@property (nonatomic, strong) NSDate *lastUpdatedDate;

@end

@implementation MITShuttleStopViewController

- (instancetype)initWithStop:(MITShuttleStop *)stop
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _stop = stop;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleStopAlarmCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleRouteNoDataCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerNoDataCellReuseIdentifier];
    
    [self startRefreshingData];
    [self setupHelpAndStatusFooter];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods

- (void)setupHelpAndStatusFooter {
    UIView *helpAndStatusFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 30)];
    helpLabel.font = [UIFont systemFontOfSize:12];
    helpLabel.textColor = [UIColor lightGrayColor];
    helpLabel.textAlignment = NSTextAlignmentCenter;
    helpLabel.text = @"Tap bell to be notified 5 min. before arrival";
    [helpAndStatusFooter addSubview:helpLabel];
    
    self.statusFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 320, 30)];
    self.statusFooterLabel.font = [UIFont systemFontOfSize:14];
    self.statusFooterLabel.textColor = [UIColor blackColor];
    self.statusFooterLabel.textAlignment = NSTextAlignmentCenter;
    [helpAndStatusFooter addSubview:self.statusFooterLabel];
    
    self.tableView.tableFooterView = helpAndStatusFooter;
}

- (void)startRefreshingData {
    [self reloadPredictions];
//    self.stopRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kStopRefreshInterval
//                                                             target:self
//                                                           selector:@selector(reloadPredictions)
//                                                           userInfo:nil
//                                                            repeats:YES];
}

- (void)reloadPredictions {
    [self updateStatusLabel];

    [[MITShuttleController sharedController] getPredictionsForStop:self.stop completion:^(NSArray *predictions, NSError *error) {
        if (error) {
            // Nothing to do, simply do not update the status label and the UI will be correct
        } else {
            self.lastUpdatedDate = [NSDate date];
            [[MITShuttleStopNotificationManager sharedManager] updateNotificationsForStop:self.stop];
            
            [self createPredictionsByRoute:predictions];
            [self.tableView reloadData];
            [self updateStatusLabel];
        }
    }];
}

- (void)updateStatusLabel {
    if (self.lastUpdatedDate) {
        self.statusFooterLabel.text = [NSString stringWithFormat:@"Updated %@", [NSDateFormatter relativeDateStringFromDate:self.lastUpdatedDate toDate:[NSDate date]]];
    }
}

- (void)createPredictionsByRoute:(NSArray *)predictions {
    NSMutableDictionary *newPredictionsByRoute = [NSMutableDictionary dictionary];
    
    for (MITShuttleRoute *route in self.stop.routes) {
        NSMutableArray *predictionsArrayForRoute = [NSMutableArray array];
        
        for (MITShuttlePredictionList *predictionList in predictions) {
            if ([predictionList.routeId isEqualToString:route.identifier] && [predictionList.stopId isEqualToString:self.stop.identifier]) {
                for (MITShuttlePrediction *prediction in predictionList.predictions) {
                    [predictionsArrayForRoute addObject:prediction];
                }
                if (predictionsArrayForRoute.count > 0) {
                    [newPredictionsByRoute setObject:predictionsArrayForRoute forKey:route.identifier];
                }
            }
        }
    }
    
    self.predictionsByRoute = [NSDictionary dictionaryWithDictionary:newPredictionsByRoute];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.stop.routes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MITShuttleRoute *route = self.stop.routes[section];
    NSArray *predictionsForRoute = self.predictionsByRoute[route.identifier];
    return predictionsForRoute.count > 0 ? predictionsForRoute.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleRoute *route = self.stop.routes[indexPath.section];
    NSArray *predictionsArray = self.predictionsByRoute[route.identifier];
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
    
    return [UITableViewCell new];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MITShuttleRoute *route = self.stop.routes[section];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 320, 44)];
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.font = [UIFont systemFontOfSize:16];
    headerLabel.text = route.title;
    
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [headerContainer addSubview:headerLabel];
    
    return headerContainer;
}

@end
