#import "MITCampusMapViewController.h"
#import "MITMapCategoryBrowseController.h"
#import "MITAdditions.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSSimpleAnnotation.h"
#import "MapBookmarkManager.h"
#import "MITMapDetailViewController.h"
#import "BookmarksTableViewController.h"
#import "MapSearch.h"
#import "CoreDataManager.h"

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
@property (nonatomic,weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic,weak) IBOutlet MGSMapView *mapView;
@property (nonatomic,strong) UISearchDisplayController *searchController; // Lazy instantiation

@property (nonatomic,getter=isSearching) BOOL searching;
@property (nonatomic,copy) NSOrderedSet *selectedPlaces;

@property (nonatomic,strong) NSManagedObjectContext *searchContext;
@property (nonatomic,copy) NSOrderedSet *recentSearches;

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

        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            // Make sure that the map view extends all the way under the toolbar in
            // iOS 7
            self.edgesForExtendedLayout = UIRectEdgeBottom;
        }
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

    MGSMapView *mapView = [[MGSMapView alloc] init];
    mapView.delegate = self;
    mapView.frame = controllerView.bounds;
    mapView.autoresizingMask = UIViewAutoresizingNone;
    [controllerView addSubview:mapView];
    self.mapView = mapView;

    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = @"Search MIT Campus";
    searchBar.translucent = YES;
    searchBar.delegate = self;
    [searchBar sizeToFit];

    CGRect searchBarFrame = searchBar.frame;
    searchBarFrame.origin = CGPointMake(CGRectGetMinX(controllerView.bounds),
                                        CGRectGetMinY(controllerView.bounds));
    searchBarFrame.size = CGSizeMake(CGRectGetWidth(controllerView.bounds), CGRectGetHeight(searchBarFrame));
    searchBar.frame = searchBarFrame;
    [controllerView addSubview:searchBar];
    self.searchBar = searchBar;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.interfaceHidden) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }

    [self updateToolbarItems:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
            self.searchContext = context;

            UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                                                            contentsController:self];
            searchController.delegate = self;
            searchController.searchResultsDataSource = self;
            searchController.searchResultsDelegate = self;
            self.searchController = searchController;
            
            [self.searchController setActive:YES animated:animated];
        } else {
            [self.searchController setActive:NO animated:animated];

            self.recentSearches = nil;
            self.searchContext = nil;
            self.searchController = nil;
        }
    }
}

#pragma mark - Browse Handling
- (IBAction)browseItemWasTapped:(UIBarButtonItem*)sender
{
    MITMapCategoryBrowseController *categoryBrowseController = [[MITMapCategoryBrowseController alloc] init:^(MITMapCategory *category, NSOrderedSet *selectedPlaces) {
        DDLogVerbose(@"Selected %d places (from categories)", [selectedPlaces count]);
        [self dismissViewControllerAnimated:YES completion:^{
            // At the moment, assume that a 'nil' value means the operation
            // was canceled. Should probably go back to the two parameters
            // (selectedPlaces and error) to indicate cancellation.
            if (selectedPlaces) {
                self.selectedPlaces = selectedPlaces;
            }
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
    BookmarksTableViewController *bookmarksViewController = [[BookmarksTableViewController alloc] init:^(NSOrderedSet *selectedPlaces) {
        DDLogVerbose(@"Selected %d places (from bookmarks)", [selectedPlaces count]);
        [self dismissViewControllerAnimated:YES completion:^{
            // At the moment, assume that a 'nil' value means the operation
            // was canceled. Should probably go back to the two parameters
            // (selectedPlaces and error) to indicate cancellation.
            if (selectedPlaces) {
                self.selectedPlaces = selectedPlaces;
            }
        }];
    }];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:bookmarksViewController];
    navigationController.navigationBarHidden = NO;
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}

- (IBAction)listItemWasTapped:(UIBarButtonItem*)sender
{

}

- (IBAction)geotrackingItemWasTapped:(UIBarButtonItem*)sender
{
    self.geotrackingEnabled = !self.isGeotrackingEnabled;
}

#pragma mark - Dynamic Properties
- (BOOL)hasFavorites
{
    return ([[[MapBookmarkManager defaultManager] bookmarks] count] > 0);
}

- (void)setSelectedPlaces:(NSOrderedSet *)selectedPlaces
{
    if (![_selectedPlaces isEqualToOrderedSet:selectedPlaces]) {
        _selectedPlaces = selectedPlaces;
        [self didChangeSelectedPlaces];
    }
}

- (void)didChangeSelectedPlaces
{
    NSMutableOrderedSet *annotations = nil;
    // Update the map with the latest list of selectedPlace or,
    // if there are none, nuke any existing annotations on the
    // map.
    // TODO: MITMapPlace object should implement the proper annotation protocols
    if (self.selectedPlaces) {
        annotations = [[NSMutableOrderedSet alloc] init];

        for (MITMapPlace *place in self.selectedPlaces) {
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

        [self.mapView defaultLayer].annotations = annotations;

        if ([annotations count]) {
            self.mapView.mapRegion = MKCoordinateRegionForMGSAnnotations([annotations set]);

            if ([annotations count] == 1) {
                [self.mapView showCalloutForAnnotation:annotations[0]];
            }
        }
    } else {
        [self.mapView defaultLayer].annotations = nil;
    }


    if ([self.selectedPlaces count]) {
        UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/item_list"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(listItemWasTapped:)];
        [self.navigationItem setRightBarButtonItem:listItem animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
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
                                 self.searchBar.transform = CGAffineTransformMakeTranslation(0., -CGRectGetHeight(self.searchBar.frame));

                                 [self.navigationController setToolbarHidden:YES
                                                                    animated:YES];
                             }
                             completion:^(BOOL finished) {
                                 self.searchBar.hidden = YES;
                             }];
        } else {

            [UIView animateWithDuration:0.25
                                  delay:0
                                options:0//UIViewAnimationOptionLayoutSubviews
                             animations:^{
                                 self.searchBar.hidden = NO;
                                 self.searchBar.transform = CGAffineTransformIdentity;
                                 [self.navigationController setToolbarHidden:NO
                                                                    animated:NO];
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
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITCampusMapReuseIdentifierSearchCell];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [[MITMapModelController sharedController] recentSearchesForPartialString:searchString
                                                                      loaded:^(NSOrderedSet *objectIDs, NSDate *lastUpdated, BOOL finished, NSError *error) {
        if (error) {
            self.recentSearches = nil;
        } else {
            NSMutableOrderedSet *recentSearches = [[NSMutableOrderedSet alloc] init];
            [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
                MapSearch *search = (MapSearch*)[self.searchContext objectWithID:objectID];
                [recentSearches addObject:search];
            }];

            self.recentSearches = recentSearches;
        }

        [controller.searchResultsTableView reloadData];
    }];
    
    return NO;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [controller.searchBar resignFirstResponder];
    self.searching = NO;
}


#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (!self.isSearching) {
        [self setSearching:YES animated:YES];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [[MITMapModelController sharedController] searchMapWithQuery:searchBar.text
                                                          loaded:^(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error) {
                                                              if (!error) {
                                                                  self.selectedPlaces = objects;
                                                              } else {
                                                                  DDLogVerbose(@"Failed to perform search '%@', %@",searchBar.text,error);
                                                              }
                                                          }];
    [searchBar resignFirstResponder];
    [self setSearching:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self setSearching:NO animated:YES];
}


#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchDisplayController.searchResultsTableView == tableView) {
        if (self.recentSearches) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchDisplayController.searchResultsTableView == tableView) {
        return [self.recentSearches count];
    }
    
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSDateFormatter *cachedFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedFormatter = [[NSDateFormatter alloc] init];
        [cachedFormatter setDoesRelativeDateFormatting:YES];
        [cachedFormatter setTimeStyle:NSDateFormatterShortStyle];
        [cachedFormatter setDateStyle:NSDateFormatterMediumStyle];
    });

    if (self.searchDisplayController.searchResultsTableView == tableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITCampusMapReuseIdentifierSearchCell
                                                                forIndexPath:indexPath];
        
        MapSearch *search = self.recentSearches[indexPath.row];
        cell.textLabel.text = search.searchTerm;
        
        [cachedFormatter setDefaultDate:[NSDate date]];
        cell.detailTextLabel.text = [cachedFormatter stringFromDate:search.date];
        
        return cell;
    } else {
        return nil;
    }
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
