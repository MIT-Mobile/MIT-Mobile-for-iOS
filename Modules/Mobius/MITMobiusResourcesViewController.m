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

#pragma mark Helper class interfaces
@interface MITMobiusResourcesTableSection : NSObject <MKAnnotation>
@property (nonatomic,readonly,copy) NSString *name;
@property (nonatomic,readonly,copy) NSString *hours;
@property (nonatomic,readonly,copy) NSArray *resources;
@property (nonatomic,readonly) BOOL isOpen;

- (instancetype)initWithName:(NSString*)name;
- (void)addResource:(MITMobiusResource *)resource;
- (BOOL)isOpenForDate:(NSDate*)date;
@end

#pragma mark - Static
NSString* const MITMobiusResourceShopHeaderReuseIdentifier = @"MITMobiusResourceShopHeader";
NSString* const MITMobiusResourceCellReuseIdentifier = @"MITMobiusResourceCell";

#pragma mark - Main Implementation
@interface MITMobiusResourcesViewController () <UITableViewDataSourceDynamicSizing, MKMapViewDelegate>
@property (nonatomic,readonly,weak) MITTiledMapView *mapView;
@property (nonatomic,copy) NSArray *sections;
@end

@implementation MITMobiusResourcesViewController {
    CGFloat _mapViewDefaultHeight;
    CGFloat _lastContentOffset;
}

@synthesize mapView = _mapView;

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _showsMap = YES;
    }

    return self;
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    _mapViewDefaultHeight = CGRectGetHeight(self.view.bounds) * 0.33;

    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.top += _mapViewDefaultHeight;
    self.tableView.contentInset = contentInset;
    [self updateMapIfNeeded:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    if ([self.delegate respondsToSelector:@selector(resourcesViewControllerShowsMapView:)]) {
        self.showsMap = [self.delegate resourcesViewControllerShowsMapView:self];
    } else {
        self.showsMap = NO;
    }

    if (self.showsMap && [self.delegate respondsToSelector:@selector(resourcesViewControllerShowsMapFullScreen:)]) {
        self.showsMapFullScreen = [self.delegate resourcesViewControllerShowsMapFullScreen:self];
    } else {
        self.showsMapFullScreen = NO;
    }


    [self updateMapIfNeeded:YES];
    [self.tableView reloadData];
}

- (void)updateMapIfNeeded:(BOOL)animated
{
    NSTimeInterval timeInterval = (animated ? 0.33 : 0.);

    [UIView animateWithDuration:timeInterval
                          delay:0.
                        options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionLayoutSubviews)
                     animations:^{
                         if (self.showsMap) {
                             CGRect mapViewFrame = self.mapView.frame;
                             if (self.showsMapFullScreen) {
                                 mapViewFrame.size.height = CGRectGetHeight(self.tableView.bounds);
                                 [self.tableView setContentOffset:mapViewFrame.origin animated:animated];
                             } else {
                                mapViewFrame.size.height = CGRectGetHeight(self.tableView.bounds) * 0.33;
                             }

                             self.mapView.frame = mapViewFrame;

                             [self.mapView.mapView removeAnnotations:self.mapView.mapView.annotations];
                             [self.mapView.mapView addAnnotations:self.sections];
                             [self.mapView.mapView showAnnotations:self.sections animated:animated];
                         } else if ([self mapViewIsLoaded]) {
                             CGRect mapViewFrame = self.mapView.frame;
                             mapViewFrame.size.height = 0.;
                             self.mapView.frame = mapViewFrame;

                         }
                     } completion:^(BOOL finished) {
                        if (self.showsMap == NO && [self mapViewIsLoaded]) {
                            [self.mapView removeFromSuperview];
                            self.tableView.scrollEnabled = YES;
                        } else if (self.showsMapFullScreen) {
                            self.tableView.scrollEnabled = NO;
                            self.mapView.userInteractionEnabled = YES;
                        } else {
                            self.tableView.scrollEnabled = YES;
                            self.mapView.userInteractionEnabled = NO;
                        }
            }];
}

#pragma mark Resources View Controller Delegate

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MITMobiusResourcesTableSection *tableSection = self.sections[section];
    return tableSection.resources.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];

    [self tableView:tableView configureView:headerFooterView forHeaderInSection:section];

    return [headerFooterView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];

    [self tableView:tableView configureView:headerFooterView forHeaderInSection:section];

    return headerFooterView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITMobiusResourceCellReuseIdentifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView configureView:(UITableViewHeaderFooterView*)headerView forHeaderInSection:(NSInteger)section {
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

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
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
        CGFloat yOffset  = scrollView.contentOffset.y;
        if (yOffset <= 0) {
            CGRect f = self.mapView.frame;
            f.origin.y = CGRectGetMinY(scrollView.bounds);
            f.size.height = _mapViewDefaultHeight + fabs(yOffset);
            self.mapView.frame = f;
        }
    }
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{

}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{

}

/* Selection Behaviors
 * iPad:
 *  Select UITableViewCell -> 
 */
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
        // Run through all the resources and:
        //  1: Update the hours string
        //      A: Iterate through the resources
        //          a: Get the hours for the current day
        //          b: Get the starting time
        //              I:      If the earliest start time is nil, replace the earliest start time
        //              II:     If the earliest start time is later than the current start time, replace the earliest start time
        //              III:    If the earliest start time is earlier than the current start time, do nothing
        //          b: Get the ending time
        //              I:      If the latest end time is nil, replace the latest end time
        //              II:     If the latest end time is earlier than the current end time, replace the latest end time
        //              III:    If the latest end time is later than the current end time, do nothing
        //          c: Assign hours string using format string @"\(earliest start hour) - \(latest end hour)"

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