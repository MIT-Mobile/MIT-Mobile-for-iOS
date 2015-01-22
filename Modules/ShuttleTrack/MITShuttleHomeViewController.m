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
#import "MITShuttleRouteViewController.h"
#import "MITShuttleResourceData.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"
#import "UITableView+MITAdditions.h"
#import "MITShuttlePredictionLoader.h"
#import "MITTelephoneHandler.h"
#import "MITShuttleRoutesDataSource.h"
#import "CoreData+MITAdditions.h"

static const NSTimeInterval kShuttleHomeAllRoutesRefreshInterval = 60.0;

static NSString * const kMITShuttlePhoneNumberCellIdentifier = @"MITPhoneNumberCell";
static NSString * const kMITShuttleURLCellIdentifier = @"MITURLCell";

static const NSInteger kMinimumNumberOfRowsForRoute = 1;
static const NSInteger kNearestStopDisplayCount = 2;

static const CGFloat kRouteSectionHeaderHeight = CGFLOAT_MIN;
static const CGFloat kRouteSectionFooterHeight = CGFLOAT_MIN;

static const CGFloat kContactInformationCellHeight = 60.0;

typedef NS_ENUM(NSUInteger, MITShuttleSection) {
    MITShuttleSectionRoutes = 0,
    MITShuttleSectionContactInformation = 1,
    MITShuttleSectionMBTAInformation = 2
};

@interface MITShuttleHomeViewController ()

@property(nonatomic,strong) MITShuttleRoutesDataSource *routesDataSource;
@property (nonatomic, readonly) NSArray *routes;

@property (copy, nonatomic) NSArray *flatRouteArray;
@property (copy, nonatomic) NSDictionary *nearestStops;
@property (nonatomic, strong) NSArray *predictionsDependentStops;
@property (nonatomic, assign) BOOL shouldAddPredictionsDependencies;
@property (nonatomic, assign) BOOL forceRefreshForNextDependencies;

@property (nonatomic, getter = isUpdating) BOOL updating;

@property (strong, nonatomic) NSTimer *routesRefreshTimer;

@property (strong, nonatomic) MITShuttleResourceData *resourceData;

@property (nonatomic) BOOL hasFetchedRoutes;

@end

@implementation MITShuttleHomeViewController

#pragma mark - Getters

- (NSArray *)routes
{
    return self.routesDataSource.routes;
}

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            self.title = @"Shuttles";
        } else {
            self.title = nil;
        }
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleBordered target:nil action:nil];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.routesDataSource = [[MITShuttleRoutesDataSource alloc] init];
    
    [self setupTableView];
    [self setupResourceData];
    
    self.tableView.rowHeight = 44.0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.shouldAddPredictionsDependencies = YES;
    self.forceRefreshForNextDependencies = YES;
    [self startRefreshingRoutes];
    
    if ([MITLocationManager locationServicesAuthorized]) {
        [[MITLocationManager sharedManager] startUpdatingLocation];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateLocation:) name:kLocationManagerDidUpdateLocationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePredictionsData) name:kMITShuttlePredictionLoaderDidUpdateNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![MITLocationManager locationServicesAuthorized]) {
        [self performSelector:@selector(requestLocationServicesAuthorization) withObject:nil afterDelay:0.75];
    }
}

- (void)requestLocationServicesAuthorization
{
    [[MITLocationManager sharedManager] requestLocationAuthorization];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.shouldAddPredictionsDependencies = NO;
    [[MITLocationManager sharedManager] stopUpdatingLocation];
    [self stopRefreshingData];
    [self removeNearestStopsPredictionsDependencies];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateLocationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMITShuttlePredictionLoaderDidUpdateNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
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

- (void)setupResourceData
{
    self.resourceData = [[MITShuttleResourceData alloc] init];
}

#pragma mark - Refresh Control

- (void)refreshControlActivated:(id)sender
{
    [self fetchRoutes];
}

#pragma mark - Data Refresh Timers

- (void)stopRefreshingData
{
    [self.routesRefreshTimer invalidate];
    self.routesRefreshTimer = nil;
}

#pragma mark - Data Refresh

- (void)startRefreshingRoutes
{
    if (!self.routesRefreshTimer) {
        [self fetchRoutes];
        
        NSTimer *routesAndPredictionsTimer = [NSTimer timerWithTimeInterval:kShuttleHomeAllRoutesRefreshInterval
                                                                     target:self
                                                                   selector:@selector(fetchRoutes)
                                                                   userInfo:nil
                                                                    repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:routesAndPredictionsTimer forMode:NSRunLoopCommonModes];
        self.routesRefreshTimer = routesAndPredictionsTimer;
    }
}

- (void)fetchRoutes
{
    [self beginRefreshing];
    [self updateRoutesData:^{
        [self endRefreshing];
    }];
}

- (void)updateRoutesData:(void(^)(void))completion
{
    [self.routesDataSource updateRoutes:^(MITShuttleRoutesDataSource *dataSource, NSError *error) {
        [self refreshFlatRouteArray:^{
            [self.tableView reloadDataAndMaintainSelection];
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)updatePredictionsData
{
    [self.tableView reloadDataAndMaintainSelection];
}

- (void)beginRefreshing
{
    if (!self.isUpdating) {
        self.updating = YES;
        
        if (!self.refreshControl.isRefreshing) {
            [self.refreshControl beginRefreshing];
            // Necessary because tableview doesn't automatically scroll to show refreshControl
            [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
        }
    }
}

- (void)endRefreshing
{
    if (self.isUpdating) {
        [self.refreshControl endRefreshing];
        self.updating = NO;
    }
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateLocation:(NSNotification *)notification
{
    CLLocation *currentLocation = [MITLocationManager sharedManager].currentLocation;
    if (!currentLocation) {
        return;
    }

    // If the location is too old, we want to a) Not update the UI, and b) Refresh the location
    if ([currentLocation.timestamp timeIntervalSinceNow] < -60) {
        [[MITLocationManager sharedManager] stopUpdatingLocation];
        [[MITLocationManager sharedManager] startUpdatingLocation];
        return;
    }
    
    [self refreshFlatRouteArray:^{
        [self.tableView reloadData];
    }];
}

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    if ([MITLocationManager locationServicesAuthorized]) {
        [[MITLocationManager sharedManager] startUpdatingLocation];
    } else {
        [self.tableView reloadData];
    }
}

#pragma mark - Highlight Stop

- (void)highlightStop:(MITShuttleStop *)stop
{
    if (stop) {
        for (id object in self.flatRouteArray) {
            if (object == stop) {
                NSInteger index = [self.flatRouteArray indexOfObject:object];
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:MITShuttleSectionRoutes] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                return;
            }
        }
    } else {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - Route Data Helpers


- (void)refreshFlatRouteArray:(void(^)(void))completion
{
    [self refreshNearestStops:^{
        NSMutableArray *mutableFlatRouteArray = [NSMutableArray array];
        
        // Sort first by In Service / Unknown / Not In Service, then by server order
        
        NSArray *sortedRoutes = [self.routes sortedArrayUsingComparator:^NSComparisonResult(MITShuttleRoute *left, MITShuttleRoute *right) {
            MITShuttleRouteStatus leftStatus = [left status];
            MITShuttleRouteStatus rightStatus = [right status];
            if (leftStatus == rightStatus) {
                return [left.order compare:right.order];
            } else if (leftStatus == MITShuttleRouteStatusInService) {
                return NSOrderedAscending;
            } else if (rightStatus == MITShuttleRouteStatusInService) {
                return NSOrderedDescending;
            } else if (leftStatus == MITShuttleRouteStatusUnknown) {
                return NSOrderedAscending;
            } else if (rightStatus == MITShuttleRouteStatusUnknown) {
                return NSOrderedDescending;
            }
            return [left.order compare:right.order];
        }];
        
        for (MITShuttleRoute *route in sortedRoutes) {
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
        
        if (completion) {
            completion();
        }
    }];
}

- (void)refreshNearestStops:(void(^)(void))completion
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:NO];
    [managedObjectContext performBlock:^{
        NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
        NSArray *blockRoutes = [managedObjectContext transferManagedObjects:self.routes];
        
        NSMutableDictionary *stopsByRouteIdentifier = [NSMutableDictionary dictionary];
        for (MITShuttleRoute *route in blockRoutes) {
            if (route.identifier) {
                stopsByRouteIdentifier[route.identifier] = [mainQueueContext transferManagedObjects:[route nearestStopsWithCount:kNearestStopDisplayCount]];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.nearestStops = stopsByRouteIdentifier;
            [self updateNearestStopsPredictionsDependencies];
            
            if (completion) {
                completion();
            }
        }];
    }];
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

#pragma mark - Predictions Dependencies

- (void)updateNearestStopsPredictionsDependencies
{
    [self removeNearestStopsPredictionsDependencies];
    [self addNearestStopsPredictionsDependencies];
}

- (void)addNearestStopsPredictionsDependencies
{
    if (![MITLocationManager locationServicesAuthorized] || !self.shouldAddPredictionsDependencies) {
        return;
    }
    
    NSMutableArray *newPredictionsDependentStops = [NSMutableArray array];
    for (NSArray *stopArray in [self.nearestStops allValues]) {
        for (MITShuttleStop *stop in stopArray) {
            if (stop.route.status == MITShuttleRouteStatusInService) {
                [newPredictionsDependentStops addObject:stop];
            }
        }
    }
    
    if (newPredictionsDependentStops.count > 0) {
        self.predictionsDependentStops = [NSArray arrayWithArray:newPredictionsDependentStops];
        [[MITShuttlePredictionLoader sharedLoader] addPredictionDependencyForStops:self.predictionsDependentStops];
        if (self.forceRefreshForNextDependencies) {
            self.forceRefreshForNextDependencies = NO;
            [[MITShuttlePredictionLoader sharedLoader] forceRefresh];
        }
    } else {
        self.predictionsDependentStops = nil;
    }
}

- (void)removeNearestStopsPredictionsDependencies
{
    if (self.predictionsDependentStops != nil) {
        [[MITShuttlePredictionLoader sharedLoader] removePredictionDependencyForStops:self.predictionsDependentStops];
        self.predictionsDependentStops = nil;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 1;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        sections += kResourceSectionCount;
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleSectionRoutes:
            return [self.flatRouteArray count];
        case MITShuttleSectionContactInformation:
            return [self.resourceData.contactInformation count];
        case MITShuttleSectionMBTAInformation:
            return [self.resourceData.mbtaInformation count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section) {
        case MITShuttleSectionRoutes: {
            id object = self.flatRouteArray[indexPath.row];
            if ([object isKindOfClass:[MITShuttleRoute class]]) {
                cell = [self tableView:tableView routeCellForRowAtIndexPath:indexPath];
            } else {
                cell = [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
            }
            break;
        }
        case MITShuttleSectionContactInformation:
            cell = [self tableView:tableView phoneNumberCellForRowAtIndexPath:indexPath];
            break;
        case MITShuttleSectionMBTAInformation:
            cell = [self tableView:tableView URLCellForRowAtIndexPath:indexPath];
            break;
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    return cell;
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
    if ([MITLocationManager locationServicesAuthorized] && route.status == MITShuttleRouteStatusInService) {
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
    MITShuttlePrediction *prediction = nil;
    if ([stop.predictionList.updatedTime timeIntervalSinceNow] >= -60) { // Make sure predictions are 60 seconds old or newer
        prediction = [stop nextPrediction];
    }
    [cell setStop:stop prediction:prediction];
    [cell setCellType:MITShuttleStopCellTypeRouteList];
    cell.separatorInset = [self stopCellSeparatorEdgeInsetsForStop:stop];
    return cell;
}

- (UIEdgeInsets)stopCellSeparatorEdgeInsetsForStop:(MITShuttleStop *)stop
{
    CGFloat leftEdgeInset = [self isLastNearestStop:stop inRoute:stop.route] ? 0 : kStopCellDefaultSeparatorLeftInset;
    return UIEdgeInsetsMake(0, leftEdgeInset, 0, 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView phoneNumberCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    }
    NSDictionary *resource = self.resourceData.contactInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    cell.detailTextLabel.text = resource[kResourceFormattedPhoneNumberKey];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    cell.detailTextLabel.textColor = [UIColor mit_greyTextColor];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView URLCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleURLCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITShuttleURLCellIdentifier];
    }
    NSDictionary *resource = self.resourceData.mbtaInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
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
            return [kContactInformationHeaderTitle uppercaseString];
        case MITShuttleSectionMBTAInformation:
            return [kMBTAInformationHeaderTitle uppercaseString];
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
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                if ([self.delegate respondsToSelector:@selector(shuttleHomeViewController:didSelectRoute:stop:)]) {
                    [self.delegate shuttleHomeViewController:self didSelectRoute:route stop:stop];
                }
                if (stop) {
                    return;
                }
            } else {
                MITShuttleRouteContainerViewController *routeContainerViewController = [[MITShuttleRouteContainerViewController alloc] initWithRoute:route stop:stop];
                [self.navigationController pushViewController:routeContainerViewController animated:YES];
            }
            break;
        }
        case MITShuttleSectionContactInformation:
            [self phoneNumberResourceSelected:self.resourceData.contactInformation[indexPath.row]];
            break;
        case MITShuttleSectionMBTAInformation:
            [self urlResourceSelected:self.resourceData.mbtaInformation[indexPath.row]];
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDelegate Helpers

- (void)phoneNumberResourceSelected:(NSDictionary *)resource
{
    NSString *phoneNumber = resource[kResourcePhoneNumberKey];
    [MITTelephoneHandler attemptToCallPhoneNumber:phoneNumber];
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
