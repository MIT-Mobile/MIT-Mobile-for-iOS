#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleController.h"
#import "MITShuttleVehicleList.h"

NSString * const kMITShuttleStopViewControllerAlarmCellReuseIdentifier = @"kMITShuttleStopViewControllerAlarmCellReuseIdentifier";

@interface MITShuttleStopViewController ()

@property (nonatomic, retain) NSDictionary *predictionsByRoute;
@property (nonatomic, retain) NSArray *vehicles;
@property (nonatomic, retain) UILabel *statusFooterLabel;

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
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:kMITShuttleStopAlarmCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier];
    
    [self reloadPredictions];
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

- (void)reloadPredictions {
    for (MITShuttlePrediction *prediction in self.stop.predictions) {
        NSLog(@"prediction1: %@", prediction);
    }
    [[MITShuttleController sharedController] getStopDetail:self.stop completion:^(MITShuttleStop *stop, NSError *error) {
        if (error) {
#warning Handle error condition
        } else {
            self.stop = stop;
            
            for (MITShuttlePrediction *prediction in self.stop.predictions) {
                NSLog(@"prediction2: %@", prediction);
            }
            
            [[MITShuttleController sharedController] getVehicles:^(NSArray *vehicles, NSError *error) {
                if (error) {
#warning Handle error condition
                } else {
                    self.vehicles = vehicles;
                    [self createPredictionsByRoute:self.stop.predictions];
                    [self.tableView reloadData];
                }
            }];
        }
    }];
}

- (void)createPredictionsByRoute:(NSOrderedSet *)predictions {
    NSMutableDictionary *newPredictionsByRoute = [NSMutableDictionary dictionary];
    NSMutableOrderedSet *newRoutes = [NSMutableOrderedSet orderedSet];
    
    for (MITShuttleRoute *route in self.stop.routes) {
        NSMutableArray *predictionsArrayForRoute = [NSMutableArray array];
        
        for (MITShuttleVehicleList *vehicleList in self.vehicles) {
            if ([vehicleList.routeId isEqualToString:route.identifier]) {
                for (MITShuttlePrediction *prediction in predictions) {
                    for (MITShuttleVehicle *vehicle in vehicleList.vehicles) {
                        if ([prediction.vehicleId isEqualToString:vehicle.identifier]) {
                            [predictionsArrayForRoute addObject:prediction];
                            [newPredictionsByRoute setObject:predictionsArrayForRoute forKey:route.identifier];
                        }
                    }
                    
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
    MITShuttleStopAlarmCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopViewControllerAlarmCellReuseIdentifier forIndexPath:indexPath];
    
    MITShuttleRoute *route = self.stop.routes[indexPath.section];
    NSArray *predictionsArray = self.predictionsByRoute[route.identifier];
    MITShuttlePrediction *prediction = nil;
    
    if (!route.scheduled) {
        [cell setNotInService];
    } else if (!route.predictable || !predictionsArray) {
        [cell setPrediction:nil];
    } else {
        prediction = predictionsArray[indexPath.row];
        [cell setPrediction:prediction];
    }
    
    return cell;
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
