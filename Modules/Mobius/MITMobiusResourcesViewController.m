#import <MapKit/MapKit.h>

#import "MITMobiusResourcesViewController.h"
#import "MITMobiusResource.h"
#import "MITMobiusResourceHours.h"
#import "Foundation+MITAdditions.h"
#import "CoreData+MITAdditions.h"
#import "MITMobiusRoomSet.h"
#import "UITableView+DynamicSizing.h"
#import "MITMobiusResourcesTableSection.h"

// UITableView Headers/Cells
#import "MITMobiusShopHeader.h"
#import "MITMobiusResourceTableViewCell.h"
#import "MITMobiusResourceView.h"
#import "MITActivityTableViewCell.h"
#import "MITMobiusNoResultsCell.h"

// Map-related classes
#import "MITMapPlaceAnnotationView.h"
#import "MITMobiusCalloutContentView.h"
#import "MITTiledMapView.h"
#import "MITCalloutView.h"

#pragma mark - Static
NSString* const MITMobiusResourceShopHeaderReuseIdentifier = @"MITMobiusResourceShopHeader";
NSString* const MITMobiusResourceCellReuseIdentifier = @"MITMobiusResourceCell";
NSString* const MITMobiusResourceLoadingCellReuseIdentifier = @"MITMobiusResourceLoadingCell";
NSString* const MITMobiusResourceNoResultsCellReuseIdentifier = @"MITMobiusResourceNoResultsCell";
NSString* const MITMobiusResourceRoomAnnotationReuseIdentifier = @"MITMobiusResourceRoomAnnotation";

#pragma mark - Main Implementation
@interface MITMobiusResourcesViewController () <UITableViewDelegate, UITableViewDataSourceDynamicSizing, MKMapViewDelegate, MITCalloutViewDelegate>
@property (nonatomic,copy) NSArray *sections;
@property (nonatomic,weak) MITLoadingActivityView *activityView;
@property (nonatomic,weak) MITCalloutView *calloutView;
@end

@implementation MITMobiusResourcesViewController {
    NSLayoutConstraint *_mapViewAspectHeightConstraint;
    NSLayoutConstraint *_mapViewFullScreenHeightConstraint;
    CGAffineTransform _mapSavedTransform;
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

- (void)viewDidLoad {
    [super viewDidLoad];

    UITableView *tableView = [[UITableView alloc] init];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"tableView" : tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"tableView" : tableView}]];
    [self setupMapView];

    UINib *resourceTableViewCellNib = [UINib nibWithNibName:@"MITMobiusResourceTableViewCell" bundle:nil];
    [self.tableView registerNib:resourceTableViewCellNib forDynamicCellReuseIdentifier:MITMobiusResourceCellReuseIdentifier];

    UINib *noResultsCellNib = [UINib nibWithNibName:@"MITMobiusNoResultsCell" bundle:nil];
    [self.tableView registerNib:noResultsCellNib forCellReuseIdentifier:MITMobiusResourceNoResultsCellReuseIdentifier];
    [self.tableView registerNib:[MITMobiusShopHeader searchHeaderNib] forHeaderFooterViewReuseIdentifier:MITMobiusResourceShopHeaderReuseIdentifier];

    [self.tableView registerClass:[MITActivityTableViewCell class] forCellReuseIdentifier:MITMobiusResourceLoadingCellReuseIdentifier];
}

- (void)setupMapView
{
    MITTiledMapView *mapView = [[MITTiledMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 0)];
    mapView.translatesAutoresizingMaskIntoConstraints = NO;
    mapView.userInteractionEnabled = NO;
    [mapView setMapDelegate:self];
    [self.view addSubview:mapView];
    self.mapView = mapView;

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mapView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.
                                                           constant:0.]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mapView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.tableView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.
                                                           constant:0.]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mapView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.tableView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.
                                                           constant:0.]];

    NSLayoutConstraint *mapHeightConstraint = [NSLayoutConstraint constraintWithItem:mapView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:mapView
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:0.66
                                                                            constant:0];
    mapHeightConstraint.priority = UILayoutPriorityDefaultHigh;
    [mapView addConstraint:mapHeightConstraint];
    _mapViewAspectHeightConstraint = mapHeightConstraint;


    NSLayoutConstraint *mapFixedHeightConstraint = [NSLayoutConstraint constraintWithItem:mapView
                                                                                attribute:NSLayoutAttributeBottom
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.bottomLayoutGuide
                                                                                attribute:NSLayoutAttributeTop
                                                                               multiplier:1.
                                                                                 constant:0.];
    mapFixedHeightConstraint.priority = UILayoutPriorityDefaultLow;
    [self.view addConstraint:mapFixedHeightConstraint];
    _mapViewFullScreenHeightConstraint = mapFixedHeightConstraint;


    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleShowMapFullScreenGesture:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delaysTouchesBegan = NO;
    gestureRecognizer.delaysTouchesEnded = NO;
    self.mapFullScreenGesture = gestureRecognizer;
    [self.view addGestureRecognizer:gestureRecognizer];

    [self.view setNeedsLayout];
}

- (void)updateViewConstraints
{
    if (self.showsMap) {
        if (self.showsMapFullScreen) {
            _mapViewAspectHeightConstraint.priority = UILayoutPriorityDefaultLow;
            _mapViewFullScreenHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        } else {
            _mapViewFullScreenHeightConstraint.priority = UILayoutPriorityDefaultLow;
            _mapViewAspectHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        }

        if (self.tableView.contentOffset.y < 0) {
            _mapViewAspectHeightConstraint.constant = -self.tableView.contentOffset.y;
        } else {
            _mapViewAspectHeightConstraint.constant = 0.;
        }
    } else {
        _mapViewFullScreenHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        _mapViewAspectHeightConstraint.priority = UILayoutPriorityDefaultLow;
    }

    [super updateViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSAssert(self.managedObjectContext,@"a valid managed object context was not configured");
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [UIView animateWithDuration:duration
                          delay:0.
                        options:(UIViewAnimationCurveLinear |
                                 UIViewAnimationOptionAllowAnimatedContent)
                     animations:^{
                         [self.view setNeedsUpdateConstraints];
                         [self.view setNeedsLayout];
                         [self.view layoutIfNeeded];
                     } completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];


    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self recenterMapView];
    }];
}

- (void)updateMapWithContentOffset:(CGPoint)contentOffset
{
    CGFloat yOffset = contentOffset.y;
    
    if (yOffset <= 0) {
        self.mapView.transform = CGAffineTransformMakeTranslation(0, 0);
    } else {
        self.mapView.transform = CGAffineTransformMakeTranslation(0, -yOffset);
    }

    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
}

#pragma mark Property accessors/setters
- (BOOL)mapViewIsLoaded
{
    return (_mapView != nil);
}

- (MITTiledMapView*)mapView
{
    if ([self mapViewIsLoaded] == NO) {
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
    }

    if (_resources.count == 0) {
        self.tableView.scrollEnabled = NO;
    } else {
        self.tableView.scrollEnabled = YES;
    }

    if ([self isViewLoaded]) {
        [self reloadData];
    }
}

- (void)setSelectedResource:(MITMobiusResource *)selectedResource
{
    if (selectedResource) {
        self.selectedResources = @[selectedResource];
    } else {
        self.selectedResources = nil;
    }
}

- (MITMobiusResource*)selectedResource
{
    return [self.selectedResources firstObject];
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
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.tableView reloadData];

    [self updateMapWithContentOffset:self.tableView.contentOffset];

    MKMapView *mapView = self.mapView.mapView;
    mapView.showsUserLocation = NO;
    mapView.userTrackingMode = MKUserTrackingModeNone;
    [mapView removeAnnotations:mapView.annotations];
    [mapView addAnnotations:self.sections];

    [self recenterMapView];
}

- (void)recenterMapView
{
    MKMapView *mapView = self.mapView.mapView;
    if (self.isLoading || (self.sections.count == 0)) {
        [mapView setRegion:kMITShuttleDefaultMapRegion animated:YES];
    } else if (self.sections.count > 0) {
        [mapView showAnnotations:self.sections animated:YES];
    }
}

- (void)setShowsMap:(BOOL)showsMap
{
    [self setShowsMap:showsMap animated:NO];
}

- (void)setShowsMap:(BOOL)showsMap animated:(BOOL)animated
{
    if (_showsMap != showsMap) {
        _showsMap = showsMap;

        NSTimeInterval duration = (animated ? 0.33 : 0.);

        [UIView animateWithDuration:duration
                              delay:0.
                            options:(UIViewAnimationOptionCurveEaseInOut |
                                     UIViewAnimationOptionAllowAnimatedContent |
                                     UIViewAnimationOptionLayoutSubviews)
                         animations:^{
                             [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                             [self recenterMapView];
                         } completion:nil];
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

        NSTimeInterval duration = (animated ? 0.33 : 0.);

        if (_showsMapFullScreen) {
            [self willShowMapFullScreen:animated];

            _mapSavedTransform = self.mapView.transform;
            [UIView animateWithDuration:duration
                                  delay:0.
                                options:(UIViewAnimationOptionCurveEaseInOut |
                                         UIViewAnimationOptionAllowAnimatedContent)
                             animations:^{
                                 self.mapView.transform = CGAffineTransformIdentity;

                                 [self.view setNeedsUpdateConstraints];
                                 [self.view setNeedsLayout];
                                 [self.view layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.tableView.userInteractionEnabled = NO;
                                 self.mapView.userInteractionEnabled = YES;

                                 [self recenterMapView];
                                 [self didShowMapFullScreen:animated];
                             }];
        } else {
            [self willHideMapFullScreen:animated];
            [UIView animateWithDuration:duration
                                  delay:0.
                                options:(UIViewAnimationOptionCurveEaseInOut |
                                         UIViewAnimationOptionAllowAnimatedContent)
                             animations:^{
                                 self.mapView.transform = _mapSavedTransform;

                                 [self.view setNeedsUpdateConstraints];
                                 [self.view setNeedsLayout];
                                 [self.view layoutIfNeeded];

                                 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                             } completion:^(BOOL finished) {
                                 self.tableView.userInteractionEnabled = YES;
                                 self.mapView.userInteractionEnabled = NO;

                                 [self recenterMapView];
                                 [self didHideMapFullScreen:animated];
                             }];
        }
    }
}

#pragma mark Delegate Pass-through
- (void)willShowMapFullScreen:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(resourceViewControllerWillShowFullScreenMap:)]) {
        [self.delegate resourceViewControllerWillShowFullScreenMap:self];
    }
}

- (void)didShowMapFullScreen:(BOOL)animated
{

    if ([self.delegate respondsToSelector:@selector(resourceViewControllerDidShowFullScreenMap:)]) {
        [self.delegate resourceViewControllerDidShowFullScreenMap:self];
    }
}

- (void)willHideMapFullScreen:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(resourceViewControllerWillHideFullScreenMap:)]) {
        [self.delegate resourceViewControllerWillHideFullScreenMap:self];
    }
}

- (void)didHideMapFullScreen:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(resourceViewControllerDidHideFullScreenMap:)]) {
        [self.delegate resourceViewControllerDidHideFullScreenMap:self];
    }
}

- (void)didSelectResource:(MITMobiusResource*)resource
{
    [self didSelectResource:resource inResources:@[resource]];
}

- (void)didSelectResources:(NSArray*)array
{
    [self didSelectResource:[array firstObject] inResources:array];
}

- (void)didSelectResource:(MITMobiusResource*)resource inResources:(NSArray*)resources
{
    if ([self.delegate respondsToSelector:@selector(resourcesViewController:didSelectResourcesWithIdentifiers:selectedResource:)]) {
        NSArray *identifiers = [[resources valueForKey:@"identifier"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@",[NSNull null]]];
        [self.delegate resourcesViewController:self didSelectResourcesWithIdentifiers:identifiers selectedResource:resource.identifier];
    }
}

#pragma mark UI updating & gesture handling
- (IBAction)handleShowMapFullScreenGesture:(UITapGestureRecognizer*)tapGesture
{
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        if (self.showsMapFullScreen == NO) {
            CGPoint tapLocation = [tapGesture locationInView:self.view];
            if (CGRectContainsPoint(self.mapView.frame, tapLocation)) {
                [self setShowsMapFullScreen:YES animated:YES];
            }
        }
    }
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
            self.tableView.scrollEnabled = NO;
        } else {
            self.tableView.scrollEnabled = YES;
        }

        [self reloadData];
    }
}

#pragma mark UI Actions
- (IBAction)tableViewHandleSectionHeaderTap:(UIButton*)sender
{
    /* Do Nothing */
}

#pragma mark - Table view data source
- (BOOL)isLoadingCellAtIndexPath:(NSIndexPath*)indexPath
{
    // Start section index at '1' since 0 is the map
    NSInteger section = 1;

    if (!self.isLoading) {
        return NO;
    } else if (indexPath.row == 0 && indexPath.section == section) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isNoResultsCellAtIndexPath:(NSIndexPath*)indexPath
{

    // Start section index at '1' since 0 is the map
    NSInteger section = 1;

    if (self.resources.count != 0) {
        return NO;
    } else if (indexPath.row == 0 && indexPath.section == section) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isMapSection:(NSInteger)section
{
    return (section == 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger numberOfSections = 0;

    if (self.isLoading) {
        // Show the loading cell
        numberOfSections = 1;
    } else if (self.sections.count == 0) {
        // Show the no-result cell
        numberOfSections = 1;
    } else {
        // Otherwise, show the number of sections we have
        numberOfSections = self.sections.count;
    }

    // Add a section for the map view
    numberOfSections += 1;

    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isMapSection:section]) {
        return 1;
    } else if (self.isLoading || (self.sections.count == 0)) {
        return 1;
    } else {
        // Decrement section to account for map section.
        NSInteger sectionIndex = section - 1;
        MITMobiusResourcesTableSection *tableSection = self.sections[sectionIndex];
        return tableSection.resources.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isMapSection:section]) {
        return 0.;
    } else if (self.isLoading || (self.sections.count == 0)) {
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
    } else if (self.isLoading || (self.sections.count == 0)) {
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
        NSInteger sectionIndex = section - 1;

        if ([headerView isKindOfClass:[MITMobiusShopHeader class]]) {
            MITMobiusShopHeader *shopHeader = (MITMobiusShopHeader*)headerView;
            MITMobiusResourcesTableSection *tableSection = self.sections[sectionIndex];
            shopHeader.shopHours = tableSection.hours;
            shopHeader.shopName = [NSString stringWithFormat:@"%ld. %@",(long)(sectionIndex + 1),tableSection.name]; // Add 1 to the index to make it 1-indexed instead of 0-indexed

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
        if ([self isLoadingCellAtIndexPath:indexPath]) {
            MITActivityTableViewCell *cell = (MITActivityTableViewCell*)[tableView dequeueReusableCellWithIdentifier:MITMobiusResourceLoadingCellReuseIdentifier forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.activityView.activityIndicatorView startAnimating];
            return cell;
        } else if ([self isNoResultsCellAtIndexPath:indexPath]) {
            MITMobiusNoResultsCell *cell = (MITMobiusNoResultsCell*)[tableView dequeueReusableCellWithIdentifier:MITMobiusResourceNoResultsCellReuseIdentifier forIndexPath:indexPath];
            cell.textLabel.text = @"No results found";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITMobiusResourceCellReuseIdentifier forIndexPath:indexPath];
            [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
            return cell;
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMapSection:indexPath.section]) {
        if (self.showsMap) {
            CGFloat mapHeight = CGRectGetHeight(self.mapView.frame);
            return mapHeight;
        } else {
            return 0;
        }
    } else if ([self isLoadingCellAtIndexPath:indexPath] || [self isNoResultsCellAtIndexPath:indexPath]) {
        return CGRectGetHeight(self.tableView.frame) - CGRectGetHeight(self.mapView.frame);
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:MITMobiusResourceCellReuseIdentifier atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isMapSection:indexPath.section]) {
        return;
    } else {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];

        if ([cell.reuseIdentifier isEqualToString:MITMobiusResourceCellReuseIdentifier]) {
            NSAssert([cell isKindOfClass:[MITMobiusResourceTableViewCell class]], @"cell for [%@,%@] is kind of %@, expected %@",cell.reuseIdentifier,indexPath,NSStringFromClass([cell class]),NSStringFromClass([MITMobiusResourceTableViewCell class]));

            MITMobiusResourceTableViewCell *resourceTableViewCell = (MITMobiusResourceTableViewCell*)cell;
            MITMobiusResource *resource = self.sections[indexPath.section][indexPath.row];

            resourceTableViewCell.resourceView.index = NSNotFound;
            resourceTableViewCell.resourceView.machineName = resource.name;
            resourceTableViewCell.resourceView.model = [resource makeAndModel];

            if ([resource.status caseInsensitiveCompare:@"online"] == NSOrderedSame) {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusOnline];
            } else if ([resource.status caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusOffline];
            } else {
                [resourceTableViewCell.resourceView setStatus:MITMobiusResourceStatusUnknown];
            }

            resourceTableViewCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMapSection:indexPath.section]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!(self.isLoading || self.sections.count == 0)) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];

        MITMobiusResourcesTableSection *tableSection = self.sections[indexPath.section];
        self.selectedResources = tableSection.resources;
        [self didSelectResource:tableSection.resources[indexPath.row] inResources:tableSection.resources];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        [self updateMapWithContentOffset:scrollView.contentOffset];
    }
}

#pragma mark MITCalloutViewDelegate
- (void)calloutView:(MITCalloutView *)calloutView positionedOffscreenWithOffset:(CGPoint)offset
{
    /* Do Nothing */
}

- (void)calloutViewTapped:(MITCalloutView *)calloutView
{
    [self didSelectResources:self.selectedResources];
}

- (void)calloutViewRemovedFromViewHierarchy:(MITCalloutView *)calloutView
{
    /* Do Nothing */
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMobiusResourcesTableSection class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:MITMobiusResourceRoomAnnotationReuseIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MITMobiusResourceRoomAnnotationReuseIdentifier];
        }

        MITMobiusResourcesTableSection *room = (MITMobiusResourcesTableSection *)annotation;
        NSUInteger index = [self.sections indexOfObject:room] + 1;
        [annotationView setNumber:index];

        return annotationView;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    MITMobiusResourcesTableSection *mapObject = (MITMobiusResourcesTableSection*)(view.annotation);
    self.selectedResources = mapObject.resources;

    MITMobiusCalloutContentView *contentView = [[MITMobiusCalloutContentView alloc] init];
    contentView.roomName = mapObject.title;
    contentView.backgroundColor = [UIColor clearColor];

    MITMobiusResource *resource = [mapObject.resources firstObject];
    NSMutableString *machineList = [[NSMutableString alloc] initWithString:resource.name];
    if (mapObject.resources.count > 1) {
        [machineList appendFormat:@" + %ld more", (unsigned long)(mapObject.resources.count - 1)];
    }

    contentView.machineList = machineList;

    if (!self.calloutView) {
        MITCalloutView *calloutView = [[MITCalloutView alloc] init];
        calloutView.delegate = self;
        calloutView.permittedArrowDirections = MITCalloutPermittedArrowDirectionAny;

        self.mapView.mapView.mitCalloutView = calloutView;
        self.calloutView = calloutView;
    }

    self.calloutView.contentView = contentView;
    self.calloutView.contentViewPreferredSize = [contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [self.calloutView presentFromRect:view.bounds inView:view withConstrainingView:self.mapView];
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MKUserTrackingModeNone) {
        mapView.showsUserLocation = NO;
        [self recenterMapView];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    mapView.userTrackingMode = MKUserTrackingModeNone;
    mapView.showsUserLocation = NO;
    [self recenterMapView];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [self.calloutView dismissCallout];
    self.selectedResources = nil;
}

@end
