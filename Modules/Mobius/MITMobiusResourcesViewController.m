#import <MapKit/MapKit.h>

#import "MITMobiusResourcesViewController.h"
#import "MITMobiusResource.h"
#import "MITMobiusResourceHours.h"
#import "Foundation+MITAdditions.h"
#import "CoreData+MITAdditions.h"
#import "MITMobiusRoomSet.h"
#import "UITableView+DynamicSizing.h"

// UITableView Headers/Cells
#import "MITMobiusShopHeader.h"
#import "MITMobiusResourceTableViewCell.h"
#import "MITMobiusResourceView.h"

#import "MITTiledMapView.h"
#import "MITLoadingActivityView.h"

#pragma mark Helper class interfaces
@interface MITMobiusResourcesTableSection : NSObject <MKAnnotation>
@property (nonatomic,readonly,copy) NSString *name;
@property (nonatomic,readonly,copy) NSString *hours;
@property (nonatomic,readonly,copy) NSArray *resources;
@property (nonatomic,readonly) BOOL isOpen;

- (instancetype)initWithName:(NSString*)name;
- (void)addResource:(MITMobiusResource*)resource;
- (BOOL)isOpenForDate:(NSDate*)date;
@end

#pragma mark - Static
NSString* const MITMobiusResourceShopHeaderReuseIdentifier = @"MITMobiusResourceShopHeader";
NSString* const MITMobiusResourceCellReuseIdentifier = @"MITMobiusResourceCell";

#pragma mark - Main Implementation
@interface MITMobiusResourcesViewController () <UITableViewDelegate, UITableViewDataSourceDynamicSizing, MKMapViewDelegate>
@property (nonatomic,copy) NSArray *sections;
@property (nonatomic,weak) MITLoadingActivityView *activityView;
@end

@implementation MITMobiusResourcesViewController {
    NSLayoutConstraint *_mapViewHeightConstraint;
}

@synthesize mapView = _mapView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _showsMap = YES;
    }

    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] init];

    // Setup the table view
    UITableView *tableView = [[UITableView alloc] init];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    [view addSubview:tableView];
    self.tableView = tableView;

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"tableView" : tableView}]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"tableView" : tableView}]];

    // Setup the map view
    MITTiledMapView *mapView = [[MITTiledMapView alloc] init];
    mapView.translatesAutoresizingMaskIntoConstraints = NO;
    mapView.userInteractionEnabled = NO;
    [view addSubview:mapView];
    self.mapView = mapView;

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapView]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"mapView" : mapView}]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"mapView" : mapView}]];
    NSLayoutConstraint *mapHeightConstraint = [NSLayoutConstraint constraintWithItem:mapView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:mapView
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:0.66
                                                                            constant:0];
    [mapView addConstraint:mapHeightConstraint];
    _mapViewHeightConstraint = mapHeightConstraint;

    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UINib *resourceTableViewCellNib = [UINib nibWithNibName:@"MITMobiusResourceTableViewCell" bundle:nil];
    [self.tableView registerNib:resourceTableViewCellNib forDynamicCellReuseIdentifier:MITMobiusResourceCellReuseIdentifier];
    [self.tableView registerNib:[MITMobiusShopHeader searchHeaderNib] forHeaderFooterViewReuseIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSAssert(self.managedObjectContext,@"a valid managed object context was not configured");
    [super viewWillAppear:animated];

    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateMapWithContentOffset:self.tableView.contentOffset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateMapWithContentOffset:(CGPoint)contentOffset
{
    CGFloat yOffset = contentOffset.y;
    if (yOffset <= 0) {
        if (!CATransform3DIsIdentity(self.mapView.layer.transform)) {
            self.mapView.layer.transform = CATransform3DIdentity;
        }

        _mapViewHeightConstraint.constant = -yOffset;
    } else {
        self.mapView.layer.transform = CATransform3DMakeTranslation(0, -yOffset, 0);
    }
}

#pragma mark Property accessors/setters
- (BOOL)mapViewIsLoaded
{
    return (_mapView != nil);
}

- (MITTiledMapView*)mapView
{
    if (self.showsMap == NO) {
        return nil;
    } else if ([self mapViewIsLoaded] == NO) {
        CGRect mapFrame = CGRectZero;
        mapFrame.size.width = CGRectGetWidth(self.tableView.bounds);
        MITTiledMapView *mapView = [[MITTiledMapView alloc] initWithFrame:mapFrame];
        [self.view addSubview:mapView];

        _mapView = mapView;
    }

    return _mapView;
}

- (void)setResources:(NSArray *)resources
{
    if (![_resources isEqualToArray:resources]) {
        self.sections = nil;

        if (resources == nil) {
            _resources = nil;
        } else {
            NSAssert(self.managedObjectContext,@"a valid managed object context was not configured");
            [self.managedObjectContext performBlockAndWait:^{
                _resources = [self.managedObjectContext transferManagedObjects:resources];
            }];
        }

        if ([self isViewLoaded]) {
            [self reloadData];
        }
    }
}

- (NSArray*)sections
{
    if (_resources == nil) {
        return nil;
    } else if (_sections == nil) {
        __block NSMutableArray *sections = [[NSMutableArray alloc] init];

        [self.managedObjectContext performBlockAndWait:^{
            NSMutableDictionary *sectionsByName = [[NSMutableDictionary alloc] init];
            [_resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
                NSString *key = nil;
                if (resource.roomset.name) {
                    key = [NSString stringWithFormat:@"%@ (%@)",resource.roomset.name, resource.room];
                } else {
                    key = [resource.room copy];
                }

                MITMobiusResourcesTableSection *section = sectionsByName[key];
                if (section == nil) {
                    section = [[MITMobiusResourcesTableSection alloc] initWithName:key];
                    sectionsByName[key] = section;
                }

                [section addResource:resource];
            }];

            NSArray *sortedSectionNames = [[sectionsByName allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
                return [key1 compare:key2 options:(NSNumericSearch | NSCaseInsensitiveSearch | NSForcedOrderingSearch)];
            }];

            [sortedSectionNames enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
                [sections addObject:sectionsByName[key]];
            }];
        }];

        _sections = sections;
    }

    return _sections;
}

#pragma mark Data Helper Methods
- (void)reloadData
{
    MKMapView *mapView = self.mapView.mapView;
    mapView.showsUserLocation = NO;
    mapView.userTrackingMode = MKUserTrackingModeNone;
    [mapView removeAnnotations:mapView.annotations];

    if (self.sections.count > 0) {
        [mapView addAnnotations:self.sections];
        [mapView showAnnotations:self.sections animated:NO];
    } else {
        [mapView setRegion:kMITShuttleDefaultMapRegion animated:NO];
    }

    [self.tableView reloadData];
}

- (void)setShowsMap:(BOOL)showsMap
{
    [self setShowsMap:showsMap animated:NO];
}

- (void)setShowsMap:(BOOL)showsMap animated:(BOOL)animated
{
    if (_showsMap != showsMap) {
        _showsMap = showsMap;

        if (!_showsMap) {
            _showsMapFullScreen = NO;
        }

        [self updateMap:animated];
    }
}

- (void)setShowsMapFullScreen:(BOOL)showsMapFullScreen
{
    [self setShowsMapFullScreen:showsMapFullScreen animated:NO];
}

- (void)setShowsMapFullScreen:(BOOL)showsMapFullScreen animated:(BOOL)animated
{
    if (_showsMapFullScreen != showsMapFullScreen) {
        _showsMapFullScreen = showsMapFullScreen;

        [self updateMap:animated];
    }
}

- (void)updateMap:(BOOL)animated
{
    [UIView animateWithDuration:0.33
                     animations:^{
                         CGFloat mapHeight = CGRectGetHeight(self.mapView.frame) - _mapViewHeightConstraint.constant;
                         if (self.showsMap) {
                             if (self.showsMapFullScreen) {
                                 CGFloat heightConstant = CGRectGetHeight(self.tableView.frame) - mapHeight;
                                 _mapViewHeightConstraint.constant = heightConstant;
                             } else {
                                 [self updateMapWithContentOffset:self.tableView.contentOffset];
                             }

                             if ([self.tableView numberOfSections] > 1) {
                                 [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
                             } else {
                                 [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
                             }
                         } else {
                             _mapViewHeightConstraint.constant = -mapHeight;
                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
                         }

                         [self.view setNeedsLayout];
                         [self.view layoutIfNeeded];
                     }];
}

- (void)setLoading:(BOOL)loading
{
    [self setLoading:loading animated:NO];
}

- (void)setLoading:(BOOL)loading animated:(BOOL)animated
{
    if (_loading != loading) {
        _loading = loading;

        if (_loading) {
            CGRect bounds = self.tableView.frame;
            CGRect remainder = CGRectZero;
            CGRect activityViewFrame = CGRectZero;

            CGFloat activityViewHeight = CGRectGetHeight(bounds) - CGRectGetHeight(self.mapView.frame) - _mapViewHeightConstraint.constant;
            CGRectDivide(bounds, &activityViewFrame, &remainder, activityViewHeight, CGRectMaxYEdge);
            MITLoadingActivityView *activityView = [[MITLoadingActivityView alloc] initWithFrame:activityViewFrame];
            activityView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:activityView];
            self.activityView = activityView;
        } else {
            [self.activityView removeFromSuperview];
        }
    }
}

#pragma mark Resources View Controller Delegate

#pragma mark - Table view data source
- (BOOL)isMapSection:(NSInteger)section
{
    return (self.showsMap && (section == 0));
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.showsMap) {
        return self.sections.count + 1;
    } else {
        return self.sections.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isMapSection:section]) {
        return 1;
    } else {
        if (self.showsMap) {
            --section;
        }

        MITMobiusResourcesTableSection *tableSection = self.sections[section];
        return tableSection.resources.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isMapSection:section]) {
        return 0.;
    } else {
        UITableViewHeaderFooterView *headerFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];

        [self tableView:tableView configureView:headerFooterView forHeaderInSection:section];

        return [headerFooterView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self isMapSection:section]) {
        return nil;
    } else {
        UITableViewHeaderFooterView *headerFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];

        [self tableView:tableView configureView:headerFooterView forHeaderInSection:section];

        return headerFooterView;
    }
}
- (void)tableView:(UITableView *)tableView configureView:(UITableViewHeaderFooterView*)headerView forHeaderInSection:(NSInteger)section {
    if ([self isMapSection:section]) {
        return;
    } else {
        if (self.showsMap) {
            --section;
        }

        if ([headerView isKindOfClass:[MITMobiusShopHeader class]]) {
            MITMobiusShopHeader *shopHeader = (MITMobiusShopHeader*)headerView;

            MITMobiusResourcesTableSection *tableSection = self.sections[section];
            shopHeader.shopHours = tableSection.hours;
            shopHeader.shopName = tableSection.name;

            if (tableSection.isOpen) {
                shopHeader.status = MITMobiusShopStatusOpen;
            } else {
                shopHeader.status = MITMobiusShopStatusClosed;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isMapSection:indexPath.section]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapViewCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MapViewCell"];
        }

        cell.contentView.backgroundColor = [UIColor clearColor];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITMobiusResourceCellReuseIdentifier forIndexPath:indexPath];
        [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMapSection:indexPath.section]) {
        CGFloat mapHeight = CGRectGetHeight(self.mapView.frame);
        mapHeight -= _mapViewHeightConstraint.constant;
        return mapHeight;
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:MITMobiusResourceCellReuseIdentifier atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isMapSection:indexPath.section]) {
        return;
    } else {
        if (self.showsMap) {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
        }

        if ([cell.reuseIdentifier isEqualToString:MITMobiusResourceCellReuseIdentifier]) {
            NSAssert([cell isKindOfClass:[MITMobiusResourceTableViewCell class]], @"cell for [%@,%@] is kind of %@, expected %@",cell.reuseIdentifier,indexPath,NSStringFromClass([cell class]),NSStringFromClass([MITMobiusResourceTableViewCell class]));

            MITMobiusResourceTableViewCell *resourceTableViewCell = (MITMobiusResourceTableViewCell*)cell;
            MITMobiusResource *resource = self.sections[indexPath.section][indexPath.row];

            resourceTableViewCell.resourceView.index = NSNotFound;
            resourceTableViewCell.resourceView.machineName = resource.name;

            if ([resource.status caseInsensitiveCompare:@"online"] == NSOrderedSame) {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusOnline];
            } else if ([resource.status caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusOffline];
            } else {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusUnknown];
            }
        }
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        [self updateMapWithContentOffset:scrollView.contentOffset];
    }
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{

}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{

}

#pragma mark MITMobiusDetailPagingDelegate
- (MITMobiusResourcesTableSection*)tableSectionForResource:(MITMobiusResource*)resource
{
    __block NSString *identifier = nil;
    [resource.managedObjectContext performBlockAndWait:^{
        identifier = [resource.identifier copy];
    }];

    __block MITMobiusResourcesTableSection *tableSection = nil;
    [self.sections enumerateObjectsUsingBlock:^(MITMobiusResourcesTableSection *section, NSUInteger idx, BOOL *stop) {
        if ([section.resources containsObject:resource]) {
            tableSection = section;
            (*stop) = YES;
        }
    }];

    return tableSection;
}

- (NSUInteger)numberOfResourcesInDetailViewController:(MITMobiusDetailContainerViewController*)viewController
{
    if (self.showsMapFullScreen) {
        MITMobiusResourcesTableSection *section = [self tableSectionForResource:viewController.currentResource];
        return section.resources.count;
    } else {
        return self.resources.count;
    }
}

- (MITMobiusResource*)detailViewController:(MITMobiusDetailContainerViewController*)viewController resourceAtIndex:(NSUInteger)index
{
    if (self.showsMapFullScreen) {
        MITMobiusResourcesTableSection *section = [self tableSectionForResource:viewController.currentResource];
        return section.resources[index];
    } else {
        return self.resources[index];
    }
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResourceWithIdentifier:(NSString*)identifier
{
    NSArray *resources = nil;
    if (self.showsMapFullScreen) {
        MITMobiusResourcesTableSection *section = [self tableSectionForResource:viewController.currentResource];
        resources = section.resources;
    } else {
        resources = self.resources;
    }

    return [resources indexOfObjectPassingTest:^BOOL(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
        return [resource.identifier isEqualToString:identifier];
    }];
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexAfterIndex:(NSUInteger)index
{
    NSArray *resources = nil;
    if (self.showsMapFullScreen) {
        MITMobiusResourcesTableSection *section = [self tableSectionForResource:viewController.currentResource];
        resources = section.resources;
    } else {
        resources = self.resources;
    }

    return ((index + 1) % resources.count);
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexBeforeIndex:(NSUInteger)index
{
    NSArray *resources = nil;
    if (self.showsMapFullScreen) {
        MITMobiusResourcesTableSection *section = [self tableSectionForResource:viewController.currentResource];
        resources = section.resources;
    } else {
        resources = self.resources;
    }

    return ((index - 1 + resources.count) % resources.count);
}

@end

@implementation MITMobiusResourcesTableSection {
    BOOL _coordinateNeedsUpdate;
    CLLocationCoordinate2D _coordinate;
}

@synthesize hours = _hours;
@synthesize resources = _resources;

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _coordinateNeedsUpdate = YES;
    }

    return self;
}

- (void)addResource:(MITMobiusResource *)resource
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (_resources) {
        [array addObjectsFromArray:_resources];
    }

    [array addObject:resource];
    _resources = [array copy];
    _hours = nil;
    _coordinateNeedsUpdate = YES;
}

- (NSString*)hours
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH";
    });

    if (_hours == nil) {
        NSDate *currentDate = [NSDate date];
        NSMutableOrderedSet *dateRanges = [[NSMutableOrderedSet alloc] init];
        [_resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
            [resource.hours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *resourceHours, BOOL *stop) {
                NSDate *startDay = [resourceHours.startDate startOfDay];
                NSDate *endDay = [resourceHours.endDate endOfDay];

                // Check to see if today's date is at least on the proper day (or lies between)
                // the min/max values of each range of open hours
                if ([currentDate dateFallsBetweenStartDate:startDay endDate:endDay]) {
                    NSString *hourRange = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:resourceHours.startDate], [dateFormatter stringFromDate:resourceHours.endDate]];
                    [dateRanges addObject:hourRange];
                }
            }];
        }];

        _hours = [[dateRanges array] componentsJoinedByString:@", "];
    }

    return _hours;
}

- (BOOL)isOpen
{
    return [self isOpenForDate:[NSDate date]];
}

- (BOOL)isOpenForDate:(NSDate*)date
{
    NSParameterAssert(date);

    __block BOOL isOpen = NO;
    [_resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
        [resource.hours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *resourceHours, BOOL *stop) {
            isOpen = [date dateFallsBetweenStartDate:resourceHours.startDate endDate:resourceHours.endDate];

            if (isOpen) {
                (*stop) = YES;
            }
        }];

        if (isOpen) {
            (*stop) = YES;
        }
    }];

    return isOpen;
}

- (MITMobiusResource*)objectAtIndexedSubscript:(NSUInteger)idx
{
    return self.resources[idx];
}

#pragma mark MKAnnotation
- (CLLocationCoordinate2D)coordinate
{
    if (_coordinateNeedsUpdate) {
        if (self.resources.count > 0) {
            __block MKMapPoint centroidPoint = MKMapPointMake(0, 0);
            __block NSUInteger pointCount = 0;

            [self.resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
                CLLocationCoordinate2D coordinate = resource.coordinate;
                if (CLLocationCoordinate2DIsValid(coordinate)) {
                    MKMapPoint mapCoordinate = MKMapPointForCoordinate(coordinate);
                    centroidPoint.x += mapCoordinate.x;
                    centroidPoint.y += mapCoordinate.y;
                    ++pointCount;
                }
            }];

            if (pointCount > 0) {
                centroidPoint.x /= (double)(pointCount);
                centroidPoint.y /= (double)(pointCount);
                _coordinate = MKCoordinateForMapPoint(centroidPoint);
            } else {
                _coordinate = kCLLocationCoordinate2DInvalid;
            }
        } else {
            _coordinate = kCLLocationCoordinate2DInvalid;
        }

        _coordinateNeedsUpdate = NO;
    }

    return _coordinate;
}

- (NSString*)title
{
    return self.name;
}

- (NSString*)subtitle
{
    return self.hours;
}

@end