#import "MITMobiusRootPhoneViewController.h"
#import "MITMobiusResourceDataSource.h"
#import "MITMobiusModel.h"
#import "MITMobiusResourcesTableViewController.h"
#import "MITMobiusDetailContainerViewController.h"
#import "MITSlidingViewController.h"
#import "MITCalloutMapView.h"
#import "MITMobiusResourcesViewController.h"

#import "MITMobiusMapViewController.h"
#import "MITMobiusRecentSearchController.h"
#import "MITMobiusAdvancedSearchViewController.h"
#import "MITMapPlaceSelector.h"

#import "DDLog.h"
#import "MITAdditions.h"
#import "MITMobiusRoomObject.h"
#import "MITMobiusRootHeader.h"
#import "MITMobiusQuickSearchTableViewCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITMobiusQuickSearchTableViewController.h"
#import "MITMobiusRoomSet.h"
#import "MITMobiusResourceType.h"
#import "MITMobiusQuickSearchHeaderTableViewCell.h"
#import "MITMobiusSearchFilterStrip.h"

typedef NS_ENUM(NSInteger, MITMobiusQuickSearchTableViewRows) {
    MITMobiusQuickSearchHeaderTableRow = 0,
    MITMobiusQuickSearchRoomSetTableRow,
    MITMobiusQuickSearchResourceTypeTableRow,
};

static NSString * const MITMobiusQuickSearchTableViewCellIdentifier = @"MITMobiusQuickSearchTableViewCellIdentifier";
static NSString * const MITMobiusQuickSearchHeaderTableViewCellIdentifier = @"MITMobiusQuickSearchHeaderTableViewCellIdentifier";
static NSTimeInterval MITMobiusRootPhoneDefaultAnimationDuration = 0.33;

@interface MITMobiusRootPhoneViewController () <MITMobiusResourcesTableViewControllerDelegate,MITMapPlaceSelectionDelegate,UISearchDisplayDelegate,UISearchBarDelegate,MITMobiusDetailPagingDelegate, MITMobiusRootViewRoomDataSource, MITMobiusSearchFilterStripDataSource, MITMobiusSearchFilterStripDelegate, UITableViewDataSourceDynamicSizing, MITMobiusAdvancedSearchDelegate, MITMobiusResourcesDelegate>

@property (nonatomic,strong) IBOutlet NSLayoutConstraint *filterStripHeightConstraint;
@property (nonatomic, strong) IBOutlet MITMobiusSearchFilterStrip *strip;

@property(nonatomic,strong) MITMobiusResourceDataSource *dataSource;

@property (nonatomic,weak) IBOutlet MITMobiusResourcesViewController *resourcesViewController;

@property(nonatomic,weak) MITMobiusRecentSearchController *recentSearchViewController;
@property(nonatomic,weak) UIView *searchBarContainer;
@property(nonatomic,weak) UISearchBar *searchBar;
@property(nonatomic,getter=isSearching) BOOL searching;
@property(nonatomic,getter=isLoading) BOOL loading;
@property(nonatomic,strong) NSTimer *searchSuggestionsTimer;

@property (nonatomic, copy) NSDictionary *rooms;
@property (nonatomic, readonly, copy) NSArray *allResources;

@end

@implementation MITMobiusRootPhoneViewController

@synthesize resourcesViewController = _resourcesViewController;
@synthesize recentSearchViewController = _recentSearchViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:YES];
    }

    [self setupNavigationBar];
    [self setupFilterStrip];
    [self setupTableView:self.quickLookupTableView];
}

- (void)setupTableView:(UITableView *)tableView
{
    [tableView registerNib:[MITMobiusQuickSearchTableViewCell quickSearchCellNib] forDynamicCellReuseIdentifier:MITMobiusQuickSearchTableViewCellIdentifier];
    
    [tableView registerNib:[MITMobiusQuickSearchHeaderTableViewCell quickSearchHeaderCellNib] forDynamicCellReuseIdentifier:MITMobiusQuickSearchHeaderTableViewCellIdentifier];

    tableView.dataSource = self;
    tableView.tableFooterView = [UIView new];
    tableView.backgroundColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewState:animated];
}

#pragma mark Data Loading/Updating
- (BOOL)didPerformSearch
{
    return (self.dataSource.query || self.dataSource.queryString);
}

- (void)reloadDataSourceWithField:(NSString*)field value:(NSString*)value completion:(void(^)(void))block
{
    NSParameterAssert(field);
    NSParameterAssert(value);

    self.loading = YES;
    [self updateViewState:YES];

    __weak MITMobiusRootPhoneViewController *weakSelf = self;
    [self.dataSource resourcesWithField:field value:value completion:^(MITMobiusResourceDataSource *dataSource, NSError *error) {
        MITMobiusRootPhoneViewController *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }

        self.loading = NO;
        
        if (error == nil) {
            [self didCompleteDataSourceLoad];
        } else {
            [self didCompleteDataSourceLoadWithError:error];
        }
        
        if (block) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:block];
        }
    }];
}

- (void)reloadDataSourceForQuery:(MITMobiusRecentSearchQuery*)query completion:(void(^)(void))block
{
    NSParameterAssert(query);

    self.loading = YES;
    [self updateViewState:YES];
    
    __weak MITMobiusRootPhoneViewController *weakSelf = self;
    [self.dataSource resourcesWithQueryObject:query completion:^(MITMobiusResourceDataSource *dataSource, NSError *error) {
        MITMobiusRootPhoneViewController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        }

        self.loading = NO;
        
        if (error == nil) {
            [self didCompleteDataSourceLoad];
        } else {
            [self didCompleteDataSourceLoadWithError:error];
        }
        
        if (block) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:block];
        }
    }];
}

- (void)reloadDataSourceForSearch:(NSString*)queryString completion:(void(^)(void))block {
    NSParameterAssert(queryString);

    self.loading = YES;
    [self updateViewState:YES];

    __weak MITMobiusRootPhoneViewController *weakSelf = self;
    [self.dataSource resourcesWithQuery:queryString completion:^(MITMobiusResourceDataSource *dataSource, NSError *error) {
        MITMobiusRootPhoneViewController *blockSelf = weakSelf;
        
        if (!blockSelf) {
            return;
        }

        self.loading = NO;

        if (error == nil) {
            [self didCompleteDataSourceLoad];
        } else {
            [self didCompleteDataSourceLoadWithError:error];
        }
        
        if (block) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:block];
        }
    }];
}

- (void)didCompleteDataSourceLoadWithError:(NSError*)error
{
    DDLogWarn(@"Error: %@",error);
    [self updateViewState:YES];
}

- (void)didCompleteDataSourceLoad
{
    self.resourcesViewController.loading = NO;
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext reset];
        self.rooms = nil;
        
        [self reloadData:NO];
    }];
    
    [self updateViewState:YES];
}

- (MITMobiusResourceDataSource*)dataSource
{
    if (!_dataSource) {
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.parentContext = self.managedObjectContext;
        MITMobiusResourceDataSource *dataSource = [[MITMobiusResourceDataSource alloc] initWithManagedObjectContext:managedObjectContext];
        _dataSource = dataSource;
    }

    return _dataSource;
}

#pragma mark UI setup
- (void)setupNavigationBar
{
    if (!_searchBarContainer) {
        UIView *searchBarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        searchBarContainer.autoresizingMask = UIViewAutoresizingNone;
        [searchBarContainer addSubview:self.searchBar];

        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:searchBarContainer
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.searchBar
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:searchBarContainer
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.searchBar
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:searchBarContainer
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.searchBar
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:searchBarContainer
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.searchBar
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:0];
        [searchBarContainer addConstraints:@[top, left, bottom, right]];
        self.navigationItem.titleView = searchBarContainer;
        self.searchBarContainer = searchBarContainer;
    }
}

- (void)setupFilterStrip
{
    self.strip.translatesAutoresizingMaskIntoConstraints = NO;
    self.strip.delegate = self;
    self.strip.dataSource = self;
}

#pragma mark UI Update Methods
- (void)updateViewState:(BOOL)animated
{
    if (self.isSearching) {
        [self showSearchingView:animated];
    } else if (self.isLoading || self.dataSource.query) {
        [self showResultsView:animated];
    } else {
        [self showInitialView:animated];
    }
}

- (void)showInitialView:(BOOL)animated
{
    NSTimeInterval animationDuration = (animated ? MITMobiusRootPhoneDefaultAnimationDuration : 0.);
    [self updateNavigationItem:animated];
    [self.searchBar setShowsCancelButton:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];

    self.quickLookupTableView.hidden = NO;
    [UIView transitionWithView:self.view
                      duration:animationDuration
                       options:0
                    animations:^{
                        self.quickLookupTableView.alpha = 1;
                        self.contentContainerView.alpha = 0;
                        self.recentSearchViewController.view.alpha = 0.;
                        self.strip.alpha = 0.;
                    } completion:^(BOOL finished) {
                        self.contentContainerView.hidden = YES;
                        self.strip.hidden = YES;
                        self.recentSearchViewController.view.hidden = YES;
                    }];
}

- (void)showSearchingView:(BOOL)animated
{
    NSTimeInterval animationDuration = (animated ? MITMobiusRootPhoneDefaultAnimationDuration : 0.);
    [self updateNavigationItem:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];

    self.recentSearchViewController.view.hidden = NO;
    [UIView transitionWithView:self.view
                      duration:animationDuration
                       options:0
                    animations:^{
                        self.recentSearchViewController.view.alpha = 1.;
                        self.contentContainerView.alpha = 0.;
                        self.quickLookupTableView.alpha = 0.;
                        self.strip.alpha = 0.;
                    } completion:^(BOOL finished) {
                        self.contentContainerView.hidden = YES;
                        self.quickLookupTableView.hidden = YES;
                        self.strip.hidden = YES;
                        [self.searchBar setShowsCancelButton:YES animated:animated];
                    }];
}

- (void)showResultsView:(BOOL)animated
{
    NSTimeInterval animationDuration = (animated ? MITMobiusRootPhoneDefaultAnimationDuration : 0.);
    [self updateNavigationItem:animated];
    [self.searchBar setShowsCancelButton:NO animated:animated];

    if (self.resourcesViewController.showsMapFullScreen) {
        UIImage *image = [UIImage imageNamed:MITImageBarButtonList];
        UIBarButtonItem *dismissMapButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(dismissFullScreenMap:)];

        self.toolbarItems = @[self.resourcesViewController.mapView.userLocationButton,[UIBarButtonItem flexibleSpace],dismissMapButton];

        [self.navigationController setToolbarHidden:NO animated:animated];
    } else {
        self.toolbarItems = nil;
        [self.navigationController setToolbarHidden:YES animated:animated];
    }

    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];

    self.contentContainerView.hidden = NO;
    self.strip.hidden = NO;
    [self.view bringSubviewToFront:self.strip];

    if (self.dataSource.query.options.count > 0) {
        self.filterStripHeightConstraint.constant = 34.;
    } else {
        self.filterStripHeightConstraint.constant = 0.;
    }

    [UIView transitionWithView:self.view
                      duration:animationDuration
                       options:0
                    animations:^{
                        self.strip.alpha = 1.;
                        self.contentContainerView.alpha = 1.;
                        self.quickLookupTableView.alpha = 0.;
                        self.recentSearchViewController.view.alpha = 0.;

                        [self.resourcesViewController setLoading:self.isLoading animated:animated];
                        [self.view layoutIfNeeded];
                    } completion:^(BOOL finished) {
                        self.quickLookupTableView.hidden = YES;
                        self.recentSearchViewController.view.hidden = YES;
                        [self.strip reloadData];
                    }];
}

- (void)updateNavigationItem:(BOOL)animated
{
    if (self.isSearching) {
        [self.navigationItem setLeftBarButtonItem:self.recentSearchViewController.clearButtonItem animated:animated];
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    } else {
        if ([self didPerformSearch]) {
            UIImage *image = [UIImage imageNamed:MITImageMobiusBackArrow];
            UIBarButtonItem *resetSearchButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStyleDone target:self action:@selector(resetSearchQuery:)];
            [self.navigationItem setLeftBarButtonItem:resetSearchButtonItem animated:animated];
        } else {
            UIBarButtonItem *drawerBarButtonItem = [MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem;
            [self.navigationItem setLeftBarButtonItem:drawerBarButtonItem animated:animated];
        }

        UIImage *image = [UIImage imageNamed:MITImageMobiusBarButtonAdvancedSearch];
        UIBarButtonItem *filterBarButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_didTapShowFilterButton:)];
        [self.navigationItem setRightBarButtonItem:filterBarButton animated:animated];
    }
}

- (void)reloadData:(BOOL)animated
{
    [self.strip reloadData];
    self.resourcesViewController.resources = self.dataSource.resources;
}


#pragma mark resourcesTableViewController
- (void)loadResourcesViewController
{
    MITMobiusResourcesViewController *resourcesViewController = [[MITMobiusResourcesViewController alloc] init];
    resourcesViewController.showsMap = YES;
    resourcesViewController.showsMapFullScreen = NO;
    resourcesViewController.delegate = self;

    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.parentContext = self.managedObjectContext;
    resourcesViewController.managedObjectContext = managedObjectContext;
    
    [self addChildViewController:resourcesViewController toView:self.tableViewContainer];
    _resourcesViewController = resourcesViewController;
}

- (MITMobiusResourcesViewController*)resourcesViewController
{
    if (!_resourcesViewController) {
        [self loadResourcesViewController];
    }
    
    return _resourcesViewController;
}


#pragma mark typeAheadViewController
- (UITableViewController*)recentSearchViewController
{
    if (!_recentSearchViewController) {
        [self loadRecentSearchViewController];
    }

    return _recentSearchViewController;
}

- (void)loadRecentSearchViewController
{
    MITMobiusRecentSearchController *recentSearchViewController = [[MITMobiusRecentSearchController alloc] init];
    recentSearchViewController.delegate = self;
    [self addChildViewController:recentSearchViewController toView:self.view];
    _recentSearchViewController = recentSearchViewController;
}

- (NSArray*)resources
{
    __block NSArray *resourceObjects = nil;
    [self.managedObjectContext performBlockAndWait:^{
        resourceObjects = [self.managedObjectContext transferManagedObjects:self.dataSource.resources];
    }];

    return resourceObjects;
}

#pragma mark - Private
- (IBAction)_didTapShowFilterButton:(UIBarButtonItem*)sender
{
    MITMobiusAdvancedSearchViewController *viewController = [[MITMobiusAdvancedSearchViewController alloc] initWithQuery:self.dataSource.query];
    viewController.delegate = self;

    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)searchSuggestionsTimerFired:(NSTimer*)timer
{
    [self.recentSearchViewController filterResultsUsingString:self.searchBar.text];
}

- (IBAction)dismissFullScreenMap:(UIBarButtonItem*)sender
{
    self.resourcesViewController.showsMapFullScreen = NO;
}

- (IBAction)resetSearchQuery:(id)sender
{
    self.dataSource.query = nil;
    self.searchBar.text = nil;
    [self updateViewState:YES];
}

- (void)addChildViewController:(UIViewController*)viewController toView:(UIView*)superview
{
    NSParameterAssert(viewController);
    NSParameterAssert(superview);
    
    
    [self addChildViewController:viewController];

    viewController.view.frame = superview.bounds;
    viewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    viewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);

    [viewController beginAppearanceTransition:YES animated:NO];
    [superview addSubview:viewController.view];
    
    [viewController endAppearanceTransition];
    [viewController didMoveToParentViewController:self];
}

- (void)removeChildViewController:(UIViewController*)viewController
{
    NSParameterAssert(viewController);
    
    [viewController willMoveToParentViewController:nil];
    [viewController beginAppearanceTransition:NO animated:NO];
    [viewController.view removeFromSuperview];
    [viewController endAppearanceTransition];
    [viewController removeFromParentViewController];
}

#pragma mark Search accessory methods
- (UISearchBar*)searchBar
{
    UISearchBar *searchBar = _searchBar;

    if (!searchBar) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchBar.placeholder = @"Search Mobius";
        searchBar.delegate = self;

        _searchBar = searchBar;
    }

    return searchBar;
}

#pragma mark - Delegation
#pragma mark MITMobiusRecentSearchControllerDelegate
- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector>*)viewController didSelectQuery:(NSString*)query
{
    self.searching = NO;
    
    self.searchBar.text = query;
    [self.searchBar resignFirstResponder];
    [self reloadDataSourceForSearch:query completion:nil];
}

#pragma mark MITMobiusResourcesTableViewControllerDelegate
- (void)resourcesTableViewController:(MITMobiusResourcesTableViewController *)tableViewController didSelectResource:(MITMobiusResource *)resource
{
    MITMobiusDetailContainerViewController *detailContainerViewController = [[MITMobiusDetailContainerViewController alloc] initWithResource:resource];
    detailContainerViewController.delegate = self;

    [self.navigationController pushViewController:detailContainerViewController animated:YES];
}

#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchSuggestionsTimer invalidate];
    self.searchSuggestionsTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                   target:self
                                                                 selector:@selector(searchSuggestionsTimerFired:)
                                                                 userInfo:nil
                                                                  repeats:NO];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searching = YES;
    [self updateViewState:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if ([self didPerformSearch]) {
        searchBar.text = self.dataSource.queryString;
    } else {
        searchBar.text = nil;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if (self.isSearching) {
        self.searching = NO;
        [self updateViewState:YES];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self reloadDataSourceForSearch:searchBar.text completion:nil];
}

- (NSDictionary*)rooms
{
    if (!_rooms) {
        NSDictionary *resourcesByBuilding = [self.dataSource resourcesGroupedByKey:@"room" withManagedObjectContext:self.managedObjectContext];

        NSMutableDictionary *rooms = [[NSMutableDictionary alloc] init];

        [resourcesByBuilding enumerateKeysAndObjectsUsingBlock:^(NSString *roomName, NSArray *resources, BOOL *stop) {

            MITMobiusRoomObject *mapObject = [[MITMobiusRoomObject alloc] init];
            mapObject.roomName = roomName;
            mapObject.resources = [NSOrderedSet orderedSetWithArray:resources];

            if (!CLLocationCoordinate2DIsValid(mapObject.coordinate)) {
                DDLogWarn(@"Coordinate for room with name %@ is invalid", roomName);
            }

            rooms[roomName] = mapObject;
        }];
        
        _rooms = rooms;
    }

    return _rooms;
}

- (NSArray*)allResources
{
    NSArray *sortedKeys = [self.rooms.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableArray *resources = [[NSMutableArray alloc] init];

    [sortedKeys enumerateObjectsUsingBlock:^(id<NSCopying> key, NSUInteger idx, BOOL *stop) {
        MITMobiusRoomObject *room = self.rooms[key];
        [resources addObjectsFromArray:[room.resources array]];
    }];

    return resources;
}

#pragma mark MITMobiusDetailPagingDelegate
- (NSUInteger)numberOfResourcesInDetailViewController:(MITMobiusDetailContainerViewController*)viewController
{
    // TODO: This approach needs some work, we should be keeping track of what chunk of data is being displayed,
    // not requiring the view controller to do it for us.
    return self.allResources.count;
}

- (MITMobiusResource*)detailViewController:(MITMobiusDetailContainerViewController*)viewController resourceAtIndex:(NSUInteger)index
{
    return self.allResources[index];
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexForResourceWithIdentifier:(NSString*)resourceIdentifier
{
    __block NSUInteger index = NSNotFound;
    [self.allResources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
        if ([resource.identifier isEqualToString:resourceIdentifier]) {
            index = idx;
            (*stop) = YES;
        }
    }];

    return index;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexAfterIndex:(NSUInteger)index
{
    return (index + 1) % self.allResources.count;
}

- (NSUInteger)detailViewController:(MITMobiusDetailContainerViewController*)viewController indexBeforeIndex:(NSUInteger)index
{
    NSArray *allResources = self.allResources;
    return ((index + allResources.count) - 1) % allResources.count;
}

#pragma mark MITMobiusRoomDataSource
- (NSInteger)numberOfRoomsForViewController:(UIViewController*)viewController
{
    return self.rooms.allKeys.count;
}

- (MITMobiusRoomObject*)viewController:(UIViewController*)viewController roomAtIndex:(NSInteger)roomIndex
{
    NSArray *buildingsArray = [self.rooms.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *key = buildingsArray[roomIndex];
    return self.rooms[key];
}

- (NSInteger)viewController:(UIViewController*)viewController numberOfResourcesInRoomAtIndex:(NSInteger)roomIndex
{
    NSArray *buildingsArray = [self.rooms.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *key = buildingsArray[roomIndex];
    MITMobiusRoomObject *room = self.rooms[key];
    return room.resources.count;
}

- (MITMobiusResource*)viewController:(UIViewController*)viewController resourceAtIndex:(NSInteger)resourceIndex inRoomAtIndex:(NSInteger)roomIndex
{
    NSArray *buildingsArray = [self.rooms.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *key = buildingsArray[roomIndex];
    MITMobiusRoomObject *room = self.rooms[key];
    return room.resources[resourceIndex];
}

#pragma mark MITMobiusSearchFilterStrip Delegate/DataSource

- (NSInteger)numberOfFiltersForStrip:(MITMobiusSearchFilterStrip *)filterStrip
{
    return self.dataSource.query.options.count;
}

- (NSString *)searchFilterStrip:(MITMobiusSearchFilterStrip *)filterStrip textForFilterAtIndex:(NSInteger)index
{
    MITMobiusSearchOption *option = self.dataSource.query.options[index];
    NSString *string = [NSString stringWithFormat:@"%@: %@",option.attribute.label,option.value];
    
    return string;
}

#pragma mark MITMobiusResourcesDelegate
- (void)resourcesViewController:(MITMobiusResourcesViewController*)viewController didSelectResourcesWithFetchRequest:(NSFetchRequest*)fetchRequest
{
    if (fetchRequest) {
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];

        if (fetchedObjects) {
            MITMobiusDetailContainerViewController *detailsViewController = [[MITMobiusDetailContainerViewController alloc] init];
            detailsViewController.resources = fetchedObjects;
            [self.navigationController pushViewController:detailsViewController animated:YES];
        }
    }
}

- (void)resourceViewControllerWillHideFullScreenMap:(MITMobiusResourcesViewController *)viewController
{
    [self updateViewState:YES];
}

- (void)resourceViewControllerWillShowFullScreenMap:(MITMobiusResourcesViewController *)viewController
{
    [self updateViewState:YES];
}

#pragma mark UITableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    CGFloat cellHeight = [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    return cellHeight;
}

- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row == MITMobiusQuickSearchResourceTypeTableRow ||
        indexPath.row == MITMobiusQuickSearchRoomSetTableRow) {
        return MITMobiusQuickSearchTableViewCellIdentifier;
    } else if (indexPath.row == MITMobiusQuickSearchHeaderTableRow) {
        return MITMobiusQuickSearchHeaderTableViewCellIdentifier;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == MITMobiusQuickSearchResourceTypeTableRow) {
        MITMobiusQuickSearchTableViewController *quickSearchVC = [[MITMobiusQuickSearchTableViewController alloc] init];
        quickSearchVC.dataSource = self.dataSource;
        quickSearchVC.typeOfObjects = MITMobiusQuickSearchResourceType;
        quickSearchVC.delegate = self;
        quickSearchVC.title = @"Machine Types";
        [self.navigationController pushViewController:quickSearchVC animated:YES];

    } else if (indexPath.row == MITMobiusQuickSearchRoomSetTableRow) {
        MITMobiusQuickSearchTableViewController *quickSearchVC = [[MITMobiusQuickSearchTableViewController alloc] init];
        quickSearchVC.dataSource = self.dataSource;
        quickSearchVC.typeOfObjects = MITMobiusQuickSearchRoomSet;
        quickSearchVC.delegate = self;
        quickSearchVC.title = @"Shops & Labs";
        [self.navigationController pushViewController:quickSearchVC animated:YES];
    }
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];

    if ([reuseIdentifier isEqualToString:MITMobiusQuickSearchTableViewCellIdentifier]) {
        if (indexPath.row == MITMobiusQuickSearchRoomSetTableRow) {
            MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
            quickSearch.label.text = @"Shops & Labs";
        } else if (indexPath.row == MITMobiusQuickSearchResourceTypeTableRow) {
            MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
            quickSearch.label.text = @"Machine Types";
        }
    }
}

- (void)applyQuickParams:(id)roomSetOrResourceType
{
    NSParameterAssert(roomSetOrResourceType);

    if ([roomSetOrResourceType isKindOfClass:[MITMobiusRoomSet class]]) {
        MITMobiusRoomSet *roomSet = (MITMobiusRoomSet*)roomSetOrResourceType;
        [self reloadDataSourceWithField:@"roomset" value:roomSet.identifier completion:nil];
    } else if ([roomSetOrResourceType isKindOfClass:[MITMobiusResourceType class]]) {
        MITMobiusResourceType *resourceType = (MITMobiusResourceType*)roomSetOrResourceType;
        [self reloadDataSourceWithField:@"_type" value:resourceType.identifier completion:nil];
    }
}

#pragma mark MITMobiusAdvancedSearchDelegate
- (void)didDismissAdvancedSearchViewController:(MITMobiusAdvancedSearchViewController *)viewController
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    MITMobiusRecentSearchQuery *query = (MITMobiusRecentSearchQuery*)[managedObjectContext objectWithID:viewController.query.objectID];

    if (query) {
        [managedObjectContext refreshObject:query mergeChanges:NO];
        [self reloadDataSourceForQuery:query completion:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)advancedSearchViewControllerDidCancelSearch:(MITMobiusAdvancedSearchViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
