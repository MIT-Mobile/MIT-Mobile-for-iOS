#import "MITCampusMapViewController.h"
#import "MITAdditions.h"
#import "MGSMapView.h"

static NSString* const MITCampusMapReuseIdentifierSearchCell = @"MITCampusMapReuseIdentifierSearchCell";

@interface MITCampusMapViewController () <UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MGSMapViewDelegate>
@property (nonatomic,weak) IBOutlet UISearchBar *searchBar; // Lazy instantiation
@property (nonatomic,weak) IBOutlet MGSMapView *mapView;    // Lazy instantiation
@property (nonatomic,strong) UISearchDisplayController *searchController;

@property (nonatomic,getter=isSearching) BOOL searching;
@property (nonatomic,copy) NSArray *searchResults;

@property (nonatomic,getter=isShowingList) BOOL showingList;
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
    mapView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth);
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

- (UISearchDisplayController*)searchController
{
    UISearchDisplayController *searchController = _searchController;

    if (!searchController) {
        searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                             contentsController:self];
        searchController.delegate = self;
        searchController.searchResultsDataSource = self;
        searchController.searchResultsDelegate = self;
        self.searchController = searchController;
    }

    return searchController;
}

#pragma mark - Search Handling
- (void)setSearching:(BOOL)searching
{
    [self setSearching:searching animated:YES];
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated
{
    if (_searching != searching) {
        _searching = searching;

        if (_searching) {
            [self.searchController setActive:YES animated:animated];
        } else {
            [self.searchController setActive:NO animated:animated];
            self.searchController = nil;
        }
    }
}

#pragma mark - Browse Handling
- (IBAction)bookmarksItemWasTapped:(UIBarButtonItem*)sender
{

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
    return YES;
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
    [toolbarItems addObject:[UIBarButtonItem fixedSpaceWithWidth:20.]];

    if (self.isGeotrackingEnabled) {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/toolbar/location-filled.png"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(geotrackingItemWasTapped:)]];
    } else {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/toolbar/location.png"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(geotrackingItemWasTapped:)]];
    }

    [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];

    if ([self hasFavorites]) {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/bookmark"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(favoritesItemWasTapped:)]];
        [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
    }

    if ([self canShowList]) {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/toolbar/list"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(listItemWasTapped:)]];
        [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
    }

    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                          target:self
                                                                          action:@selector(bookmarksItemWasTapped:)]];

    [toolbarItems addObject:[UIBarButtonItem fixedSpaceWithWidth:20.]];

    [self setToolbarItems:toolbarItems
                 animated:animated];
}

#pragma mark - Delegate Methods
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));

    UISearchBar *searchBar = controller.searchBar;
    searchBar.autoresizingMask = (UIViewAutoresizingFlexibleHeight);

    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = searchBar.frame;
        frame.origin.y = 20.;
        searchBar.frame = frame;
    }];

}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITCampusMapReuseIdentifierSearchCell];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    [controller.searchBar becomeFirstResponder];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));

    CGRect frame = controller.searchBar.frame;
    frame.origin = self.view.bounds.origin;
    controller.searchBar.frame = frame;
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
        self.searching = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    self.searching = NO;
}


#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
    self.interfaceHidden = !self.isInterfaceHidden;
}

- (void)mapViewRegionDidChange:(MGSMapView *)mapView
{
    if (!self.isInterfaceHidden && !self.isSearching) {
        self.interfaceHidden = YES;
    }
}
@end
