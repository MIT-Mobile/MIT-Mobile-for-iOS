#import "MITCampusMapViewController.h"
#import "MITAdditions.h"
#import "MGSMapView.h"

static NSString* const MITCampusMapReuseIdentifierSearchCell = @"MITCampusMapReuseIdentifierSearchCell";

@interface MITCampusMapViewController () <UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,weak) IBOutlet UISearchBar *searchBar; // Lazy instantiation
@property (nonatomic,weak) IBOutlet MGSMapView *mapView;    // Lazy instantiation
@property (nonatomic,strong) UISearchDisplayController *searchController;

@property (nonatomic,getter=isSearching) BOOL searching;
@property (nonatomic,copy) NSArray *searchResults;

@property (nonatomic,getter=isShowingList) BOOL showingList;

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
}

- (void)viewDidAppear:(BOOL)animated
{

    UIBarButtonItem *locationItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/toolbar/location"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:nil
                                                                    action:nil];

    UIBarButtonItem *bookmarksItems = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:nil action:nil];
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftSpace.width = 20.;
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    rightSpace.width = 20.;

    NSArray *toolbarItems = @[leftSpace,
                              locationItem,
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              bookmarksItems,
                              rightSpace];

    [self setToolbarItems:toolbarItems animated:animated];
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
- (IBAction)browseButtonTapped:(id)sender
{

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

@end
