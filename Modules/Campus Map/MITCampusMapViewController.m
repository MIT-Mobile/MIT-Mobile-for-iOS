#import "MITCampusMapViewController.h"
#import "MITMapCategoryBrowseController.h"
#import "MITAdditions.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSSimpleAnnotation.h"
#import "MapBookmarkManager.h"
#import "MITMapDetailViewController.h"

static NSString* const MITCampusMapReuseIdentifierSearchCell = @"MITCampusMapReuseIdentifierSearchCell";

// Used in the updateToolbarItems: method to determine
// the sorted order of the bar items. There starting value
// was picked at random and has no significance.
typedef NS_ENUM(NSInteger, MITCampusMapItemTag) {
    MITCampusMapItemTagGeotrackingItem = 0xFF00,
    MITCampusMapItemTagFavoritesItem,
    MITCampusMapItemTagBrowseItem
};

@interface MITCampusMapViewController () <UISearchDisplayDelegate, UISearchBarDelegate,
                                            UITableViewDataSource, UITableViewDelegate,
                                            MGSMapViewDelegate>
@property (nonatomic,weak) IBOutlet UISearchBar *searchBar; // Lazy instantiation
@property (nonatomic,weak) IBOutlet MGSMapView *mapView;    // Lazy instantiation
@property (nonatomic,strong) UISearchDisplayController *searchController; // Lazy instantiation

@property (nonatomic,getter=isSearching) BOOL searching;
@property (nonatomic,copy) NSOrderedSet *selectedPlaces;

@property (nonatomic,getter = isShowingList) BOOL showingList;
@property (nonatomic,getter = isGeotrackingEnabled) BOOL geotrackingEnabled;
@property (nonatomic,getter = isInterfaceHidden) BOOL interfaceHidden;

@end

@implementation MITCampusMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarWhenPushed = NO;
    }
    return self;
}

- (void)loadView
{
    UIView *controllerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    controllerView.backgroundColor = [UIColor mit_backgroundColor];
    controllerView.autoresizesSubviews = YES;
    controllerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
    self.view = controllerView;

    MGSMapView *mapView = self.mapView;
    mapView.frame = controllerView.bounds;
    mapView.autoresizingMask = UIViewAutoresizingNone;
    [controllerView addSubview:mapView];

    UISearchBar *searchBar = self.searchBar;
    searchBar.delegate = self;
    [searchBar sizeToFit];

    CGRect searchBarFrame = searchBar.frame;
    searchBarFrame.origin = CGPointMake(CGRectGetMinX(controllerView.bounds),
                                        CGRectGetMinY(controllerView.bounds));
    searchBarFrame.size = CGSizeMake(CGRectGetWidth(controllerView.bounds), CGRectGetHeight(searchBarFrame));
    searchBar.frame = searchBarFrame;
    [controllerView addSubview:searchBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self updateToolbarItems:animated];
}

- (void)viewDidAppear:(BOOL)animated
{

}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 0

#pragma mark - Lazy properties
- (MGSMapView*)mapView
{
    MGSMapView *mapView = _mapView;
    if (!mapView) {
        mapView = [[MGSMapView alloc] init];
        mapView.delegate = self;
        self.mapView = mapView;
    }

    return mapView;
}

- (UISearchBar*)searchBar
{
    UISearchBar *searchBar = _searchBar;
    if (!searchBar) {
        searchBar = [[UISearchBar alloc] init];
        searchBar.placeholder = @"Search MIT Campus";
        searchBar.translucent = YES;
        self.searchBar = searchBar;
    }

    return searchBar;
}

#pragma mark - Search Handling
- (void)setSearching:(BOOL)searching
{
    [self setSearching:searching animated:NO];
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated
{
    if (_searching != searching) {
        _searching = searching;
        
        if (_searching) {
            UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                                                            contentsController:self];
            searchController.delegate = self;
            searchController.searchResultsDataSource = self;
            searchController.searchResultsDelegate = self;
            self.searchController = searchController;
            
            [self.searchController setActive:YES animated:animated];
        } else {
            [self.searchController setActive:NO animated:animated];
            [self.navigationController setToolbarHidden:NO animated:animated];
            self.searchController = nil;
        }
    }
}

#pragma mark - Browse Handling
- (IBAction)browseItemWasTapped:(UIBarButtonItem*)sender
{
    MITMapCategoryBrowseController *categoryBrowseController = [[MITMapCategoryBrowseController alloc] init:^(NSOrderedSet *selectedPlaces) {
        DDLogVerbose(@"Selected %d places", [selectedPlaces count]);
        [self dismissViewControllerAnimated:YES completion:^{
            self.selectedPlaces = selectedPlaces;
        }];
    }];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:categoryBrowseController];
    navigationController.navigationBarHidden = NO;
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}

- (IBAction)favoritesItemWasTapped:(UIBarButtonItem*)sender
{

}

- (IBAction)listItemWasTapped:(UIBarButtonItem*)sender
{

}

- (IBAction)geotrackingItemWasTapped:(UIBarButtonItem*)sender
{
    self.geotrackingEnabled = !self.isGeotrackingEnabled;
}

#pragma mark - Dynamic Properties
- (BOOL)canShowList
{
    return YES;
}

- (BOOL)hasFavorites
{
    return ([[[MapBookmarkManager defaultManager] bookmarks] count] > 0);
}

- (void)setSelectedPlaces:(NSOrderedSet *)selectedPlaces
{
    if (![_selectedPlaces isEqualToOrderedSet:selectedPlaces]) {
        _selectedPlaces = selectedPlaces;

        NSMutableOrderedSet *annotations = nil;
        if ([self.selectedPlaces count]) {
            annotations = [[NSMutableOrderedSet alloc] init];

            for (MITMapPlace *place in selectedPlaces) {
                MGSSimpleAnnotation *mapAnnotation = [[MGSSimpleAnnotation alloc] init];

                if (place.buildingNumber) {
                    mapAnnotation.title = [NSString stringWithFormat:@"Building %@", place.buildingNumber];

                    if (place.name && ![place.name isEqualToString:mapAnnotation.title]) {
                        mapAnnotation.detail = place.name;
                    }
                } else {
                    mapAnnotation.title = place.name;
                }

                mapAnnotation.coordinate = place.coordinate;
                mapAnnotation.representedObject = place;
                [annotations addObject:mapAnnotation];
            }


            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/item_list"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(listItemWasTapped:)];
            self.navigationItem.rightBarButtonItem = listItem;
            [self.navigationItem setRightBarButtonItem:listItem animated:YES];
        }

        [self.mapView defaultLayer].annotations = annotations;
        self.mapView.mapRegion = MKCoordinateRegionForMGSAnnotations([annotations set]);

        if ([annotations count] == 1) {
            [self.mapView showCalloutForAnnotation:annotations[0]];
        }
    }
}

- (void)setGeotrackingEnabled:(BOOL)geotrackingEnabled
{
    if (self.geotrackingEnabled != geotrackingEnabled) {
        _geotrackingEnabled = geotrackingEnabled;
        self.mapView.trackUserLocation = _geotrackingEnabled;

        [self updateToolbarItems:YES];
    }
}

- (void)setInterfaceHidden:(BOOL)interfaceHidden
{
    if (self.interfaceHidden != interfaceHidden) {
        _interfaceHidden = interfaceHidden;

        if (_interfaceHidden) {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:(UIViewAnimationOptionAllowAnimatedContent |
                                         UIViewAnimationOptionLayoutSubviews)
                             animations:^{
                                 CGRect searchBarFrame = self.searchBar.frame;
                                 searchBarFrame.origin.y = CGRectGetMinY(self.view.bounds) - CGRectGetHeight(searchBarFrame);
                                 self.searchBar.frame = searchBarFrame;

                                 [self.navigationController setToolbarHidden:YES
                                                                    animated:YES];
                             }
                             completion:^(BOOL finished) {
                                 self.searchBar.hidden = YES;
                             }];
        } else {
            self.searchBar.hidden = NO;

            [UIView animateWithDuration:0.25
                                  delay:0
                                options:(UIViewAnimationOptionAllowAnimatedContent |
                                         UIViewAnimationOptionLayoutSubviews)
                             animations:^{
                                 CGRect searchBarFrame = self.searchBar.frame;
                                 searchBarFrame.origin.y = CGRectGetMinY(self.view.bounds);
                                 self.searchBar.frame = searchBarFrame;

                                 [self.navigationController setToolbarHidden:NO
                                                                    animated:YES];
                             }
                             completion:^(BOOL finished) {

                             }];

        }
    }
}

#pragma mark - UI State management
- (void)updateToolbarItems:(BOOL)animated
{
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] init];

    UIBarButtonItem *geotrackingItem = nil;
    if (self.isGeotrackingEnabled) {
        geotrackingItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/item_location-filled"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(geotrackingItemWasTapped:)];
    } else {
        geotrackingItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/item_location"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(geotrackingItemWasTapped:)];
    }
    geotrackingItem.tag = MITCampusMapItemTagGeotrackingItem;
    [toolbarItems addObject:geotrackingItem];

    if ([self hasFavorites]) {
        UIBarButtonItem *favoritesItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/bookmark"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(favoritesItemWasTapped:)];
        favoritesItem.tag = MITCampusMapItemTagFavoritesItem;
        [toolbarItems addObject:favoritesItem];
    }

    
    UIBarButtonItem *browseItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                target:self
                                                                                action:@selector(browseItemWasTapped:)];
    browseItem.tag = MITCampusMapItemTagBrowseItem;
    [toolbarItems addObject:browseItem];
    
    // Sort the toolbar items into their proper order
    // This uses the assigned tags for the sorted order
    // of the items and then inserts spaces as needed between them
    [toolbarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        return [@(view1.tag) compare:@(view2.tag)];
    }];

    NSUInteger maxIndex = [toolbarItems count] - 1;
    [[toolbarItems copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx < maxIndex) {
            [toolbarItems insertObject:[UIBarButtonItem flexibleSpace]
                               atIndex:((2 * idx) + 1)];
        }
    }];
    
    [toolbarItems insertObject:[UIBarButtonItem fixedSpaceWithWidth:20.] atIndex:0];
    [toolbarItems addObject:[UIBarButtonItem fixedSpaceWithWidth:20.]];

    [self setToolbarItems:toolbarItems
                 animated:animated];
}

#pragma mark - Delegate Methods
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         CGRect frame = controller.searchBar.frame;
                         frame.origin.y = CGRectGetMaxY([[UIApplication sharedApplication] statusBarFrame]);
                         controller.searchBar.frame = frame;
                     }
                     completion:^(BOOL finished) {
                            [self.navigationController setToolbarHidden:YES animated:NO];
                     }];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITCampusMapReuseIdentifierSearchCell];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    [UIView animateWithDuration:0.25
                     animations:^{
                         CGRect frame = controller.searchBar.frame;
                         frame.origin.y = CGRectGetMinY(self.view.bounds);
                         controller.searchBar.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         [self.navigationController setToolbarHidden:NO animated:YES];
                     }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    [controller.searchBar resignFirstResponder];
    self.searching = NO;
}


#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    if (!self.isSearching) {
        [self setSearching:YES animated:YES];
    }
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    [self setSearching:NO animated:YES];
}


#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchDisplayController.searchResultsTableView == tableView) {
    
    }
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark UITableViewDelegate


#pragma mark MGSMapViewDelegate
- (void)mapView:(MGSMapView *)mapView userLocationUpdateFailedWithError:(NSError *)error
{
    self.geotrackingEnabled = NO;
}

- (void)mapView:(MGSMapView *)mapView didReceiveTapAtCoordinate:(CLLocationCoordinate2D)coordinate screenPoint:(CGPoint)screenPoint
{
    self.interfaceHidden = !self.interfaceHidden;
}

- (void)mapView:(MGSMapView *)mapView calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation
{
    MGSSimpleAnnotation *simpleAnnotation = (MGSSimpleAnnotation*)annotation;
    MITMapDetailViewController *detailController = [[MITMapDetailViewController alloc] init];
    detailController.place = (MITMapPlace*)simpleAnnotation.representedObject;

    [self.navigationController pushViewController:detailController animated:YES];
}
@end
