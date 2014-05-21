#import "MITShuttleHomeViewController.h"
#import "MITShuttleRouteCell.h"
#import "MITShuttleStopCell.h"
#import "MITShuttleController.h"
#import "MITLocationManager.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttlePrediction.h"
#import "UIKit+MITAdditions.h"

static const NSTimeInterval kRoutesRefreshInterval = 60.0;
static const NSTimeInterval kPredictionsRefreshInterval = 10.0;

static NSString * const kMITShuttleRouteCellNibName = @"MITShuttleRouteCell";
static NSString * const kMITShuttleRouteCellIdentifier = @"MITShuttleRouteCell";

static NSString * const kMITShuttleStopCellNibName = @"MITShuttleStopCell";
static NSString * const kMITShuttleStopCellIdentifier = @"MITShuttleStopCell";

static NSString * const kMITShuttlePhoneNumberCellIdentifier = @"MITPhoneNumberCell";
static NSString * const kMITShuttleURLCellIdentifier = @"MITURLCell";

static NSString * const kContactInformationHeaderTitle = @"Contact Information";
static NSString * const kMBTAInformationHeaderTitle = @"MBTA Information";

static const NSInteger kRouteCellRow = 0;
static const NSInteger kNearestStopDisplayCount = 2;

static const NSInteger kResourceSectionCount = 2;

static const CGFloat kRouteSectionHeaderHeight = CGFLOAT_MIN;
static const CGFloat kRouteSectionFooterHeight = CGFLOAT_MIN;

static const CGFloat kContactInformationCellHeight = 60.0;

static NSString * const kResourceDescriptionKey = @"description";
static NSString * const kResourcePhoneNumberKey = @"phoneNumber";
static NSString * const kResourceFormattedPhoneNumberKey = @"formattedPhoneNumber";
static NSString * const kResourceURLKey = @"url";

typedef enum {
    MITShuttleResourceSectionContactInformation = 0,
    MITShuttleResourceSectionMBTAInformation = 1
} MITShuttleResourceSection;

@interface MITShuttleHomeViewController ()

@property (weak, nonatomic) IBOutlet UITableView *routesTableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationStatusLabel;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSFetchedResultsController *routesFetchedResultsController;
@property (nonatomic, readonly) NSArray *routes;

@property (strong, nonatomic) NSFetchedResultsController *predictionListsFetchedResultsController;
@property (nonatomic, readonly) NSArray *predictionLists;

@property (copy, nonatomic) NSDictionary *nearestStops;

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
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupRoutesTableView];
    [self setupResourceData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startRefreshingRoutes];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopRefreshingData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupRoutesTableView
{
    [self.routesTableView registerNib:[UINib nibWithNibName:kMITShuttleRouteCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleRouteCellIdentifier];
    [self.routesTableView registerNib:[UINib nibWithNibName:kMITShuttleStopCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
    [self.routesTableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
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
            if ([self.routes count] == 0) {
                [self.routesFetchedResultsController performFetch:nil];
            }
            [self refreshNearestStops];
            [self.routesTableView reloadData];
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
                    if ([self.predictionLists count] == 0) {
                        [self.predictionListsFetchedResultsController performFetch:nil];
                    }
                    NSInteger routeIndex = [self.routes indexOfObject:route];
                    [self.routesTableView reloadSections:[NSIndexSet indexSetWithIndex:routeIndex] withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
        }
    }
}

- (void)beginRefreshing
{
    [self.refreshControl beginRefreshing];
    [self refreshLastUpdatedLabel];
}

- (void)endRefreshing
{
    [self.refreshControl endRefreshing];
    self.lastUpdatedDate = [NSDate date];
    [self refreshLastUpdatedLabel];
}

#pragma mark - Toolbar Labels

- (void)refreshLastUpdatedLabel
{
    NSString *lastUpdatedText;
    if (self.refreshControl.isRefreshing) {
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
    self.locationStatusLabel.text = [MITLocationManager locationServicesEnabled] ? @"Showing nearest stops" : @"Location couldn't be determined";
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    [self refreshLocationStatusLabel];
}

#pragma mark - Route Data Helpers

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

- (MITShuttlePrediction *)predictionForStop:(MITShuttleStop *)stop inRoute:(MITShuttleRoute *)route
{
    for (MITShuttlePredictionList *predictionList in self.predictionLists) {
        if ([predictionList.stopId isEqualToString:stop.identifier] && [predictionList.routeId isEqualToString:route.identifier]) {
            return [predictionList.predictions firstObject];
        }
    }
    return nil;
}

#pragma mark - Resource Section Helpers

- (NSInteger)sectionIndexForResourceSection:(MITShuttleResourceSection)section
{
    return [self.routes count] + section;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.routes count] + kResourceSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return 2;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return 3;
    } else {
        NSInteger count = 1;    // always show at least the route cell
        MITShuttleRoute *route = self.routes[section];
        if ([route.scheduled boolValue]) {
            count += [self.nearestStops[route.identifier] count];
        }
        return count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return [self tableView:tableView phoneNumberCellForRowAtIndexPath:indexPath];
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return [self tableView:tableView URLCellForRowAtIndexPath:indexPath];
    } else {
        switch (indexPath.row) {
            case kRouteCellRow: {
                return [self tableView:tableView routeCellForRowAtIndexPath:indexPath];
            }
            default: {
                return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - UITableViewDataSource Helpers

- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleRouteCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleRouteCellIdentifier forIndexPath:indexPath];
    NSInteger routeIndex = indexPath.section;
    [cell setRoute:self.routes[routeIndex]];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleStopCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopCellIdentifier forIndexPath:indexPath];
    NSInteger routeIndex = indexPath.section;
    NSInteger stopIndex = indexPath.row - 1;
    MITShuttleRoute *route = self.routes[routeIndex];
    MITShuttleStop *stop = [self nearestStopForRoute:self.routes[routeIndex] atIndex:stopIndex];
    MITShuttlePrediction *prediction = [self predictionForStop:stop inRoute:route];
    [cell setStop:stop prediction:prediction];
    [cell setCellType:MITShuttleStopCellTypeRouteList];
    return cell;
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
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return kContactInformationHeaderTitle;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return kMBTAInformationHeaderTitle;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation] ||
        section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return tableView.sectionHeaderHeight;
    }
    return kRouteSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSInteger lastRouteSection = [self.routes count] - 1;
    if (section < lastRouteSection) {
        return kRouteSectionFooterHeight;
    } else {
        return tableView.sectionFooterHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return kContactInformationCellHeight;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return tableView.rowHeight;
    } else {
        switch (indexPath.row) {
            case kRouteCellRow:
                return [MITShuttleRouteCell cellHeightForRoute:nil];
            default:
                return tableView.rowHeight;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        NSDictionary *resource = self.contactInformation[indexPath.row];
        NSString *phoneNumber = resource[kResourcePhoneNumberKey];
		NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:phoneNumberURL]) {
			[[UIApplication sharedApplication] openURL:phoneNumberURL];
        }
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        NSDictionary *resource = self.mbtaInformation[indexPath.row];
        NSString *urlString = resource[kResourceURLKey];
        NSURL *url = [NSURL URLWithString:urlString];
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
        }
    } else {
#warning TODO: push route/stop view controller
    }
}

@end
