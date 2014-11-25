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

static const NSTimeInterval kRoutesRefreshInterval = 60.0;
static const NSTimeInterval kPredictionsRefreshInterval = 10.0;

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

@property (strong, nonatomic) MITShuttleResourceData *resourceData;

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
    NSArray *routes = [self.routesFetchedResultsController fetchedObjects];
    if (routes.count == 0) {
        routes = [self loadDefaultRoutes];
    }
    return routes;
}

- (NSArray *)loadDefaultRoutes
{
    NSArray *defaultRoutes = [MITShuttleController loadDefaultShuttleRoutes];
    [self.routesFetchedResultsController performFetch:nil];
    return defaultRoutes;
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
    
    [self updateDisplayedRoutes];
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
    self.resourceData = [[MITShuttleResourceData alloc] init];
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
    NSTimer *routesRefreshTimer = [NSTimer timerWithTimeInterval:kRoutesRefreshInterval
                                                          target:self
                                                        selector:@selector(loadRoutes)
                                                        userInfo:nil
                                                         repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:routesRefreshTimer forMode:NSRunLoopCommonModes];
    self.routesRefreshTimer = routesRefreshTimer;
}

- (void)startRefreshingPredictions
{
    [self loadPredictions];
    NSTimer *predictionsRefreshTimer = [NSTimer timerWithTimeInterval:kPredictionsRefreshInterval
                                                               target:self
                                                             selector:@selector(loadPredictions)
                                                             userInfo:nil
                                                              repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:predictionsRefreshTimer forMode:NSRunLoopCommonModes];
    self.predictionsRefreshTimer = predictionsRefreshTimer;
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
            [self updateDisplayedRoutes];
            
            // Start refreshing predications if we are still in the view hierarchy
            if (!self.predictionsRefreshTimer.isValid && self.navigationController) {
                [self startRefreshingPredictions];
            }
        }
    }];
}

- (void)updateDisplayedRoutes
{
    [self.routesFetchedResultsController performFetch:nil];
    [self refreshFlatRouteArray];
    [self.tableView reloadDataAndMaintainSelection];
}

- (void)loadPredictions
{
    for (MITShuttleRoute *route in self.routes) {
        if ([route.scheduled boolValue] && [route.predictable boolValue]) {
            [[MITShuttleController sharedController] getPredictionsForRoute:route completion:^(NSArray *predictions, NSError *error) {
                if (!error) {
                    [self.predictionListsFetchedResultsController performFetch:nil];
                    [self.tableView reloadDataAndMaintainSelection];
                    [self refreshFlatRouteArray];
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
        NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdatedDate
                                                                            toDate:[NSDate date]];
        lastUpdatedText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
    }
    self.lastUpdatedLabel.text = lastUpdatedText;
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

- (void)refreshFlatRouteArray
{
    [self refreshNearestStops];
    
    NSMutableArray *mutableFlatRouteArray = [NSMutableArray array];
    
    NSArray *sortedRoutes = [self.routes sortedArrayUsingComparator:^NSComparisonResult(MITShuttleRoute *left, MITShuttleRoute *right) {
        MITShuttleRouteStatus leftStatus = [left status];
        MITShuttleRouteStatus rightStatus = [right status];
        if (leftStatus == rightStatus) {
            return [left.order compare:right.order];
        } else if (leftStatus == MITShuttleRouteStatusInService) {
            return NSOrderedAscending;
        } else if (rightStatus == MITShuttleRouteStatusInService) {
            return NSOrderedDescending;
        } else if (leftStatus == MITShuttleRouteStatusNotInService) {
            return NSOrderedAscending;
        } else if (rightStatus == MITShuttleRouteStatusNotInService) {
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
    NSDictionary *resource = self.resourceData.contactInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
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
