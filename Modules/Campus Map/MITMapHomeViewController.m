#import "MITMapHomeViewController.h"
#import "MITMapModelController.h"
#import "MITMapPlace.h"
#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMapResultsListViewController.h"
#import "MITMapBrowseContainerViewController.h"
#import "CoreData+MITAdditions.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";

@interface MITMapHomeViewController () <UISearchBarDelegate, MKMapViewDelegate, MITTiledMapViewButtonDelegate, MITMapResultsListViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *bookmarksBarButton;
@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UILabel *searchResultsCountLabel;
@property (nonatomic) BOOL searchBarShouldBeginEditing;

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, readonly) MKMapView *mapView;
@property (nonatomic, copy) NSArray *places;

@property (nonatomic, strong) UITableView *resultsTableView;
@property (nonatomic, strong) NSArray *recentSearchItems;
@property (nonatomic, strong) NSArray *webserviceSearchItems;
@property (nonatomic, strong) NSString *currentSearchString;

@end

@implementation MITMapHomeViewController

#pragma mark - Map View

- (MKMapView *)mapView
{
    return self.tiledMapView.mapView;
}

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchBarShouldBeginEditing = YES;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    [self setupMapView];
    [self setupResultsTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self registerForKeyboardNotifications];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupResultsCountLabel];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.navigationItem setHidesBackButton:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self setupMapBoundingBoxAnimated:YES];
}

#pragma mark - Setup

- (void)setupNavigationBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-10, 0, 340, 44)];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search MIT Campus";
    // Insert the correct clear button image and uncomment the next line when ready
//    [searchBar setImage:[UIImage imageNamed:@""] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBarView.autoresizingMask = 0;
    self.searchBar.delegate = self;
    [searchBarView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarView;
    
    self.bookmarksBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(bookmarksButtonPressed)];
    [self.navigationItem setRightBarButtonItem:self.bookmarksBarButton];
    
    self.menuBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton];
}

// Must be called after viewDidAppear
- (void)setupResultsCountLabel
{
    if (self.searchResultsCountLabel) {
        [self.searchResultsCountLabel removeFromSuperview];
    }
    
    for (UIView *subview in self.searchBar.subviews) {
        for (UIView *secondLevelSubview in subview.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                self.searchResultsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(searchBarTextField.frame.origin.x + searchBarTextField.frame.size.width - 80, searchBarTextField.frame.origin.y, 80, searchBarTextField.frame.size.height)];
                
                self.searchResultsCountLabel.textAlignment = NSTextAlignmentRight;
                self.searchResultsCountLabel.font = [UIFont systemFontOfSize:13];
                self.searchResultsCountLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
                [self setSearchResultsCountHidden:YES];
                
                [subview addSubview:self.searchResultsCountLabel];
                break;
            }
        }
    }
}

- (void)setupMapView
{
    self.tiledMapView.buttonDelegate = self;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self setupMapBoundingBoxAnimated:NO];
}

#pragma mark - Button Actions

- (void)setupResultsTableView
{
    self.resultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, -100, self.view.frame.size.width, 0)];
    self.resultsTableView.delegate = self;
    self.resultsTableView.dataSource = self;
    [self.view addSubview:self.resultsTableView];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)bookmarksButtonPressed
{
    MITMapBrowseContainerViewController *browseContainerViewController = [[MITMapBrowseContainerViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browseContainerViewController];
    navigationController.navigationBarHidden = YES;
    navigationController.toolbarHidden = NO;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)menuButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Search Bar

- (void)closeSearchBar:(UISearchBar *)searchBar
{
    self.navigationItem.leftBarButtonItem = self.menuBarButton;
    self.navigationItem.rightBarButtonItem = self.bookmarksBarButton;
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)setSearchBarTextColor:(UIColor *)color
{
    // A public API would be preferable, but UIAppearance doesn't update unless you remove the view from superview and re-add, which messes with the display
    for (UIView *subview in self.searchBar.subviews) {
        for (UIView *secondLevelSubview in subview.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = color;
                break;
            }
        }
    }
}

- (void)setSearchResultsCount:(NSInteger)count
{
    if (count == 1) {
        self.searchResultsCountLabel.text = [NSString stringWithFormat:@"1 Result"];
    } else {
        self.searchResultsCountLabel.text = [NSString stringWithFormat:@"%i Results", count];
    }
    
}

- (void)setSearchResultsCountHidden:(BOOL)hidden
{
    self.searchResultsCountLabel.hidden = hidden;
}

#pragma mark - Map View

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    if ([self.places count] > 0) {
        [self.mapView showAnnotations:self.places animated:animated];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

- (void)setPlaces:(NSArray *)places
{
    [self setPlaces:places animated:NO];
}

- (void)setPlaces:(NSArray *)places animated:(BOOL)animated
{
    _places = places;
    [self refreshPlaceAnnotations];
    [self setupMapBoundingBoxAnimated:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    [self setPlaces:nil animated:animated];
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.places];
}

- (void)removeAllPlaceAnnotations
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITMapPlace class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGFloat navBarHeight = 64;
    CGRect endFrame = [[notification.userInfo valueForKeyPath:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSLog(@"show end frame: %@", NSStringFromCGRect(endFrame));
    CGFloat tableViewHeight = self.view.frame.size.height - endFrame.size.height - navBarHeight;
    self.resultsTableView.frame = CGRectMake(0, -tableViewHeight, self.view.frame.size.width, tableViewHeight);
    [self.resultsTableView reloadData];
    [UIView animateWithDuration:0.5 animations:^{
        self.resultsTableView.frame = CGRectMake(0, navBarHeight, self.view.frame.size.width, tableViewHeight);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.5 animations:^{
        self.resultsTableView.frame = CGRectMake(0, -self.resultsTableView.frame.size.height, self.view.frame.size.width, self.resultsTableView.frame.size.height);
    }];
}

- (void)updateSearchResultsForSearchString:(NSString *)searchString
{
    if ([searchString isEqualToString:@""]) {
        searchString = nil;
    }
    
    self.currentSearchString = searchString;
    
    __weak MITMapHomeViewController *blockSelf = self;
    
    // The error cases in these blocks are left unhandled on purpose for now. Not sure if the user ever needs to be informed
    [[MITMapModelController sharedController] recentSearchesForPartialString:searchString loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (![blockSelf isCurrentSearchStringEqualTo:searchString]) {
            return;
        }
        if (fetchRequest) {
            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            [[MITCoreDataController defaultController] performBackgroundFetch:fetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
                if (![blockSelf isCurrentSearchStringEqualTo:searchString]) {
                    return;
                }
                self.recentSearchItems = [managedObjectContext objectsWithIDs:[fetchedObjectIDs array]];
                [self.resultsTableView reloadData];
            }];
        }
    }];
    
    if (searchString) {
        [[MITMapModelController sharedController] searchMapWithQuery:searchString loaded:^(NSArray *objects, NSError *error) {
            if (![blockSelf isCurrentSearchStringEqualTo:searchString]) {
                return;
            }
            self.webserviceSearchItems = objects;
            [self.resultsTableView reloadData];
        }];
    }
}

- (BOOL)isCurrentSearchStringEqualTo:(NSString *)searchString
{
    if (searchString == nil && self.currentSearchString == nil) {
        return YES;
    } else if ([searchString isEqualToString:self.currentSearchString]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    [searchBar setShowsCancelButton:YES animated:YES];
    [self updateSearchResultsForSearchString:nil];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self closeSearchBar:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];

    [[MITMapModelController sharedController] addRecentSearch:searchBar.text];
    [[MITMapModelController sharedController] searchMapWithQuery:searchBar.text
                                                          loaded:^(NSArray *objects, NSError *error) {
                                                              if (objects) {
                                                                  [self setPlaces:objects animated:YES];
                                                              }
                                                          }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateSearchResultsForSearchString:searchText];
    
    if (!searchBar.isFirstResponder) {
        self.searchBarShouldBeginEditing = NO;
        [self clearPlacesAnimated:YES];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    BOOL shouldBeginEditing = self.searchBarShouldBeginEditing;
    self.searchBarShouldBeginEditing = YES;
    return shouldBeginEditing;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if ([searchBar.text length] == 0) {
        [self clearPlacesAnimated:YES];
    }
}

#pragma mark - MITTiledMapViewButtonDelegate

- (void)mitTiledMapViewRightButtonPressed:(MITTiledMapView *)mitTiledMapView
{
    // TODO: initialize results list VC properly if category/place was selected as search query
    MITMapResultsListViewController *resultsListViewController = [[MITMapResultsListViewController alloc] initWithPlaces:self.places];
    resultsListViewController.delegate = self;
    [resultsListViewController setTitleWithSearchQuery:self.searchBar.text];
    
    UINavigationController *resultsListNavigationController = [[UINavigationController alloc] initWithRootViewController:resultsListViewController];
    [self presentViewController:resultsListNavigationController animated:YES completion:nil];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITMapPlace class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        NSInteger placeIndex = [self.places indexOfObject:annotation];
        [annotationView setNumber:(placeIndex + 1)];
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITMapPlace *place = view.annotation;
        // TODO: push place detail view controller
    }
}

#pragma mark - MITMapResultsListViewControllerDelegate

- (void)resultsListViewController:(MITMapResultsListViewController *)viewController didSelectPlace:(MITMapPlace *)place
{
    if ([self.places containsObject:place]) {
        [self.mapView selectAnnotation:place animated:YES];
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return self.recentSearchItems.count;
            break;
        }
        case 1: {
            return self.webserviceSearchItems.count;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    switch (indexPath.section) {
        case 0: {
            MITMapSearch *searchItem = self.recentSearchItems[indexPath.row];
            cell.textLabel.text = searchItem.searchTerm;
            break;
        }
        case 1: {
            MITMapPlace *searchItem = self.webserviceSearchItems[indexPath.row];
            cell.textLabel.text = searchItem.name;
            break;
        }
        default: {
            break;
        }
    }
    
    return cell;
}

@end
