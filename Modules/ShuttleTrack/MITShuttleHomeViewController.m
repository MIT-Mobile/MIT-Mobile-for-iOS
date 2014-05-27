#import "MITShuttleHomeViewController.h"
#import "MITShuttleRouteCell.h"
#import "MITShuttleStopCell.h"
#import "MITShuttleController.h"
#import "MITLocationManager.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleRouteContainerViewController.h"
#import "UIKit+MITAdditions.h"

static const NSTimeInterval kRoutesRefreshInterval = 60.0;
static const NSTimeInterval kPredictionsRefreshInterval = 10.0;

static NSString * const kMITShuttlePhoneNumberCellIdentifier = @"MITPhoneNumberCell";
static NSString * const kMITShuttleURLCellIdentifier = @"MITURLCell";

static NSString * const kContactInformationHeaderTitle = @"Contact Information";
static NSString * const kMBTAInformationHeaderTitle = @"MBTA Information";

static const NSInteger kNumberOfSectionsInTableView = 3;
static const NSInteger kMinimumNumberOfRowsForRoute = 1;
static const NSInteger kNearestStopDisplayCount = 2;

static const CGFloat kRouteSectionHeaderHeight = CGFLOAT_MIN;
static const CGFloat kRouteSectionFooterHeight = CGFLOAT_MIN;

static const CGFloat kContactInformationCellHeight = 60.0;

static NSString * const kResourceDescriptionKey = @"description";
static NSString * const kResourcePhoneNumberKey = @"phoneNumber";
static NSString * const kResourceFormattedPhoneNumberKey = @"formattedPhoneNumber";
static NSString * const kResourceURLKey = @"url";

typedef NS_ENUM(NSUInteger, MITShuttleSection) {
    MITShuttleSectionRoutes = 0,
    MITShuttleSectionContactInformation = 1,
    MITShuttleSectionMBTAInformation = 2
};

@interface MITShuttleHomeViewController ()

@property (weak, nonatomic) IBOutlet UIView *toolbarLabelView;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationStatusLabel;

@property (strong, nonatomic) NSFetchedResultsController *routesFetchedResultsController;
@property (nonatomic, readonly) NSArray *routes;

@property (strong, nonatomic) NSFetchedResultsController *predictionListsFetchedResultsController;
@property (nonatomic, readonly) NSArray *predictionLists;

@property (copy, nonatomic) NSArray *flatRouteArray;
@property (copy, nonatomic) NSDictionary *nearestStops;

@property (nonatomic, getter = isUpdating) BOOL updating;
@property (strong, nonatomic) NSDate *lastUpdatedDate;

@property (strong, nonatomic) NSTimer *routesRefreshTimer;
@property (strong, nonatomic) NSTimer *predictionsRefreshTimer;

@property (copy, nonatomic) NSArray *contactInformation;
@property (copy, nonatomic) NSArray *mbtaInformation;

@end

@implementation MITShuttleHomeViewController

#pragma mark - Getters

- (NSFetchedResultsController *)routesFetchedResultsController
{
    if (!_routesFetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleRoute entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
        
        _routesFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                              managedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]
                                                                                sectionNameKeyPath:nil
                                                                                         cacheName:nil];
        _routesFetchedResultsController.delegate = self;
    }
    return _routesFetchedResultsController;
}

- (NSArray *)routes
{
    return [self.routesFetchedResultsController fetchedObjects];
}

- (NSFetchedResultsController *)predictionListsFetchedResultsController
{
    if (!_predictionListsFetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttlePredictionList entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"routeId" ascending:YES]];
        
        _predictionListsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                       managedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]
                                                                                         sectionNameKeyPath:nil
                                                                                                  cacheName:nil];
        _predictionListsFetchedResultsController.delegate = self;
    }
    return _predictionListsFetchedResultsController;
}

- (NSArray *)predictionLists
{
    return [self.predictionListsFetchedResultsController fetchedObjects];
}

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Shuttles";
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleBordered target:nil action:nil];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupTableView];
    [self setupToolbar];
    [self setupResourceData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [[MITLocationManager sharedManager] startUpdatingLocation];
    [self startRefreshingRoutes];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateLocation:) name:kLocationManagerDidUpdateLocationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[MITLocationManager sharedManager] stopUpdatingLocation];
    [self stopRefreshingData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateLocationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleRouteCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleRouteCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MITShuttleStopCell class]) bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)setupToolbar
{
    UIBarButtonItem *toolbarLabelItem = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelView];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace], toolbarLabelItem, [UIBarButtonItem flexibleSpace]]];
}

- (void)setupResourceData
{
    // TODO: these phone numbers and links should be provided by the server, not hardcoded
	self.contactInformation = @[
                                @{kResourceDescriptionKey:          @"Parking Office",
                                  kResourcePhoneNumberKey:          @"16172586510",
                                  kResourceFormattedPhoneNumberKey: @"617.258.6510"},
                                @{kResourceDescriptionKey:          @"Saferide",
                                  kResourcePhoneNumberKey:          @"16172532997",
                                  kResourceFormattedPhoneNumberKey: @"617.253.2997"}
                                ];
	
    self.mbtaInformation = @[
                             @{kResourceDescriptionKey: @"Real-time Bus Arrivals",
                               kResourceURLKey:         @"http://www.nextbus.com/webkit"},
                             @{kResourceDescriptionKey: @"Real-time Train Arrivals",
                               kResourceURLKey:         @"http://www.mbtainfo.com/"},
                             @{kResourceDescriptionKey: @"Google Transit",
                               kResourceURLKey:         @"http://www.google.com/transit"}
                             ];
}

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self stopRefreshingData];
    [self startRefreshingRoutes];
}

#pragma mark - Data Refresh Timers

- (void)startRefreshingRoutes
{
    [self loadRoutes];
    self.routesRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRoutesRefreshInterval
                                                               target:self
                                                             selector:@selector(loadRoutes)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (void)startRefreshingPredictions
{
    [self loadPredictions];
    self.predictionsRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kPredictionsRefreshInterval
                                                                    target:self
                                                                  selector:@selector(loadPredictions)
                                                                  userInfo:nil
                                                                   repeats:YES];
}

- (void)stopRefreshingData
{
    [self.routesRefreshTimer invalidate];
    [self.predictionsRefreshTimer invalidate];
}

#pragma mark - Data Refresh

- (void)loadRoutes
{
    [self beginRefreshing];
    [[MITShuttleController sharedController] getRoutes:^(NSArray *routes, NSError *error) {
        [self endRefreshing];
        if (!error) {
            [self.routesFetchedResultsController performFetch:nil];
            [self refreshFlatRouteArray];
            [self.tableView reloadData];
            if (!self.predictionsRefreshTimer.isValid) {
                [self startRefreshingPredictions];
            }
        }
    }];
}

- (void)loadPredictions
{
    for (MITShuttleRoute *route in self.routes) {
        if ([route.scheduled boolValue] && [route.predictable boolValue]) {
            [[MITShuttleController sharedController] getPredictionsForRoute:route completion:^(NSArray *predictions, NSError *error) {
                if (!error) {
                    [self.predictionListsFetchedResultsController performFetch:nil];
                    [self.tableView reloadData];
                }
            }];
        }
    }
}

- (void)beginRefreshing
{
    self.updating = YES;
    [self.refreshControl beginRefreshing];
    [self refreshLastUpdatedLabel];
}

- (void)endRefreshing
{
    self.updating = NO;
    [self.refreshControl endRefreshing];
    self.lastUpdatedDate = [NSDate date];
    [self refreshLastUpdatedLabel];
}

#pragma mark - Toolbar Labels

- (void)refreshLastUpdatedLabel
{
    NSString *lastUpdatedText;
    if (self.isUpdating) {
        lastUpdatedText = @"Updating...";
    } else {
        NSTimeInterval secondsSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:self.lastUpdatedDate];
        if (secondsSinceLastUpdate < 60) {
            lastUpdatedText = @"Updated just now";
        } else if (secondsSinceLastUpdate < 60 * 10) {
            NSInteger minutesSinceLastUpdate = floor(secondsSinceLastUpdate / 60);
            lastUpdatedText = [NSString stringWithFormat:@"Updated %d minute%@ ago", minutesSinceLastUpdate, (minutesSinceLastUpdate > 1) ? @"s" : @""];
        } else {
            NSString *timeString = [[[self dateFormatter] stringFromDate:self.lastUpdatedDate] lowercaseString];
            lastUpdatedText = [NSString stringWithFormat:@"Last updated at %@", timeString];
        }
    }
    self.lastUpdatedLabel.text = lastUpdatedText;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return _dateFormatter;
}

- (void)refreshLocationStatusLabel
{
    self.locationStatusLabel.text = [MITLocationManager locationServicesAuthorized] ? @"Showing nearest stops" : @"Location couldn't be determined";
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateLocation:(NSNotification *)notification
{
    [self refreshFlatRouteArray];
    [self.tableView reloadData];
}

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    if ([MITLocationManager locationServicesAuthorized]) {
        [self refreshFlatRouteArray];
    }
    [self refreshLocationStatusLabel];
    [self.tableView reloadData];
}

#pragma mark - Route Data Helpers

- (void)refreshFlatRouteArray
{
    [self refreshNearestStops];
    
    NSMutableArray *mutableFlatRouteArray = [NSMutableArray array];
    for (MITShuttleRoute *route in self.routes) {
        for (NSInteger indexInRoute = 0; indexInRoute < [self numberOfRowsForRoute:route]; ++indexInRoute) {
            if (indexInRoute == 0) {
                [mutableFlatRouteArray addObject:route];
            } else {
                NSInteger stopIndex = indexInRoute - 1;
                [mutableFlatRouteArray addObject:[self nearestStopForRoute:route atIndex:stopIndex]];
            }
        }
    }
    self.flatRouteArray = [NSArray arrayWithArray:mutableFlatRouteArray];
}

- (void)refreshNearestStops
{
    NSMutableDictionary *mutableStopsDictionary = [NSMutableDictionary dictionary];
    for (MITShuttleRoute *route in self.routes) {
        mutableStopsDictionary[route.identifier] = [route nearestStopsWithCount:kNearestStopDisplayCount];
    }
    self.nearestStops = [NSDictionary dictionaryWithDictionary:mutableStopsDictionary];
}

- (MITShuttleStop *)nearestStopForRoute:(MITShuttleRoute *)route atIndex:(NSInteger)index
{
    if (index < kNearestStopDisplayCount) {
        NSArray *stops = self.nearestStops[route.identifier];
        if (index < [stops count]) {
            return stops[index];
        }
    }
    return nil;
}

- (MITShuttleRoute *)routeForStopAtIndexInFlatRouteArray:(NSInteger)index
{
    // Start with object before stop, traverse backward until the first route is reached
    for (NSInteger i = index - 1; i >= 0; --i) {
        id object = self.flatRouteArray[i];
        if ([object isKindOfClass:[MITShuttleRoute class]]) {
            return object;
        }
    }
    return nil;
}

- (BOOL)isLastNearestStop:(MITShuttleStop *)stop inRoute:(MITShuttleRoute *)route
{
    NSInteger lastNearestStopIndex = kNearestStopDisplayCount - 1;
    return ([self nearestStopForRoute:route atIndex:lastNearestStopIndex] == stop);
}

- (MITShuttlePrediction *)predictionForStop:(MITShuttleStop *)stop inRoute:(MITShuttleRoute *)route
{
    for (MITShuttlePredictionList *predictionList in self.predictionLists) {
        if ([predictionList.stopId isEqualToString:stop.identifier] && [predictionList.routeId isEqualToString:route.identifier]) {
            return [predictionList.predictions firstObject];
        }
    }
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSectionsInTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleSectionRoutes:
            return [self.flatRouteArray count];
        case MITShuttleSectionContactInformation:
            return [self.contactInformation count];
        case MITShuttleSectionMBTAInformation:
            return [self.mbtaInformation count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITShuttleSectionRoutes: {
            id object = self.flatRouteArray[indexPath.row];
            if ([object isKindOfClass:[MITShuttleRoute class]]) {
                return [self tableView:tableView routeCellForRowAtIndexPath:indexPath];
            } else {
                return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
            }
        }
        case MITShuttleSectionContactInformation:
            return [self tableView:tableView phoneNumberCellForRowAtIndexPath:indexPath];
        case MITShuttleSectionMBTAInformation:
            return [self tableView:tableView URLCellForRowAtIndexPath:indexPath];
        default:
            return nil;
    }
}

#pragma mark - UITableViewDataSource Helpers

- (NSInteger)numberOfRowsInRouteSection
{
    NSInteger count = 0;
    for (MITShuttleRoute *route in self.routes) {
        count += [self numberOfRowsForRoute:route];
    }
    return count;
}

- (NSInteger)numberOfRowsForRoute:(MITShuttleRoute *)route
{
    NSInteger count = kMinimumNumberOfRowsForRoute;    // always show at least the route cell
    if ([MITLocationManager locationServicesAuthorized] && [route.scheduled boolValue]) {
        count += [self.nearestStops[route.identifier] count];
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleRouteCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleRouteCellIdentifier forIndexPath:indexPath];
    MITShuttleRoute *route = self.flatRouteArray[indexPath.row];
    [cell setRoute:route];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleStopCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopCellIdentifier forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    MITShuttleStop *stop = self.flatRouteArray[row];
    MITShuttleRoute *route = [self routeForStopAtIndexInFlatRouteArray:row];
    MITShuttlePrediction *prediction = [self predictionForStop:stop inRoute:route];
    [cell setStop:stop prediction:prediction];
    [cell setCellType:MITShuttleStopCellTypeRouteList];
    cell.separatorInset = [self stopCellSeparatorEdgeInsetsForStop:stop inRoute:route];
    return cell;
}

- (UIEdgeInsets)stopCellSeparatorEdgeInsetsForStop:(MITShuttleStop *)stop inRoute:(MITShuttleRoute *)route
{
    CGFloat leftEdgeInset = [self isLastNearestStop:stop inRoute:route] ? 0 : kStopCellDefaultSeparatorLeftInset;
    return UIEdgeInsetsMake(0, leftEdgeInset, 0, 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView phoneNumberCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    }
    NSDictionary *resource = self.contactInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.detailTextLabel.text = resource[kResourceFormattedPhoneNumberKey];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView URLCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleURLCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITShuttleURLCellIdentifier];
    }
    NSDictionary *resource = self.mbtaInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleSectionRoutes:
            return nil;
        case MITShuttleSectionContactInformation:
            return kContactInformationHeaderTitle;
        case MITShuttleSectionMBTAInformation:
            return kMBTAInformationHeaderTitle;
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleSectionContactInformation:
        case MITShuttleSectionMBTAInformation:
            return tableView.sectionHeaderHeight;
        default:
            return kRouteSectionHeaderHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleSectionContactInformation:
        case MITShuttleSectionMBTAInformation:
            return tableView.sectionFooterHeight;
        default:
            return kRouteSectionFooterHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITShuttleSectionRoutes: {
            id object = self.flatRouteArray[indexPath.row];
            if ([object isKindOfClass:[MITShuttleRoute class]]) {
                return [MITShuttleRouteCell cellHeightForRoute:object];
            } else {
                return tableView.rowHeight;
            }
        }
        case MITShuttleSectionContactInformation:
            return kContactInformationCellHeight;
        case MITShuttleSectionMBTAInformation:
            return tableView.rowHeight;
        default:
            return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case MITShuttleSectionRoutes: {
            MITShuttleRoute *route;
            MITShuttleStop *stop;
            id object = self.flatRouteArray[indexPath.row];
            if ([object isKindOfClass:[MITShuttleRoute class]]) {
                route = object;
            } else {
                stop = object;
                route = [self routeForStopAtIndexInFlatRouteArray:indexPath.row];
            }
            MITShuttleRouteContainerViewController *routeContainerViewController = [[MITShuttleRouteContainerViewController alloc] initWithRoute:route stop:stop];
            [self.navigationController pushViewController:routeContainerViewController animated:YES];
            break;
        }
        case MITShuttleSectionContactInformation:
            [self phoneNumberResourceSelected:self.contactInformation[indexPath.row]];
            break;
        case MITShuttleSectionMBTAInformation:
            [self urlResourceSelected:self.mbtaInformation[indexPath.row]];
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate Helpers

- (void)phoneNumberResourceSelected:(NSDictionary *)resource
{
    NSString *phoneNumber = resource[kResourcePhoneNumberKey];
    NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    if ([[UIApplication sharedApplication] canOpenURL:phoneNumberURL]) {
        [[UIApplication sharedApplication] openURL:phoneNumberURL];
    }
}

- (void)urlResourceSelected:(NSDictionary *)resource
{
    NSString *urlString = resource[kResourceURLKey];
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
