#import "MITMartyPadHomeViewController.h"
#import "MITMapModelController.h"
#import "MITMapPlace.h"
#import "MITTiledMapView.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITMartyResultsListViewController.h"
#import "MITMapBrowseContainerViewController.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITMapPlaceDetailViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITMapTypeAheadTableViewController.h"
#import "MITSlidingViewController.h"
#import "MITLocationManager.h"
#import "SMCalloutView.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";

static NSString * const kMITMapSearchSuggestionsTimerUserInfoKeySearchText = @"kMITMapSearchSuggestionsTimerUserInfoKeySearchText";
static NSTimeInterval const kMITMapSearchSuggestionsTimerWaitDuration = 0.3;

typedef NS_ENUM(NSUInteger, MITMapSearchQueryType) {
    MITMapSearchQueryTypeText,
    MITMapSearchQueryTypePlace,
    MITMapSearchQueryTypeCategory
};

@interface MITMartyPadHomeViewController () <UISearchBarDelegate, MKMapViewDelegate, UIPopoverControllerDelegate, MITMartyResultsListViewControllerDelegate, MITMapPlaceSelectionDelegate, SMCalloutViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *bookmarksBarButton;
@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UIButton *listViewToggleButton;
@property (nonatomic) BOOL searchBarShouldBeginEditing;
@property (nonatomic) MITMapSearchQueryType searchQueryType;
@property (nonatomic, strong) MITMapTypeAheadTableViewController *typeAheadViewController;
@property (nonatomic, strong) UIPopoverController *typeAheadPopoverController;
@property (nonatomic) BOOL isShowingIpadResultsList;
@property (nonatomic, strong) SMCalloutView *calloutView;
@property (nonatomic, strong) UIViewController *calloutViewController;
@property (nonatomic, strong) MITMapPlace *currentlySelectedPlace;

@property (nonatomic, strong) UIPopoverController *bookmarksPopoverController;

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, readonly) MITCalloutMapView *mapView;
@property (nonatomic) BOOL showFirstCalloutOnNextMapRegionChange;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;

@property (nonatomic, copy) NSString *searchQuery;
@property (nonatomic, copy) NSArray *places;
@property (nonatomic, strong) MITMapCategory *category;
@property (nonatomic, strong) UIView *searchBarView;
@property (nonatomic) BOOL isKeyboardVisible;

@property (nonatomic, strong) NSTimer *searchSuggestionsTimer;
@end

@implementation MITMartyPadHomeViewController

#pragma mark - Map View

- (MITCalloutMapView *)mapView
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
    [self setupTypeAheadTableView];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {        
        // We use actual UIButtons so that we can easily change the selected state
        UIImage *listToggleImageNormal = [UIImage imageNamed:MITImageBarButtonList];
        listToggleImageNormal = [listToggleImageNormal imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *listToggleImageSelected = [UIImage imageNamed:MITImageBarButtonListSelected];
        listToggleImageSelected = [listToggleImageSelected imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        // Use size of selected image because it is the largest.
        CGSize listToggleImageSize = listToggleImageSelected.size;
        self.listViewToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, listToggleImageSize.width, listToggleImageSize.height)];
        [self.listViewToggleButton setImage:listToggleImageNormal forState:UIControlStateNormal];
        [self.listViewToggleButton setImage:listToggleImageSelected forState:UIControlStateSelected];
        [self.listViewToggleButton addTarget:self action:@selector(ipadListButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.listViewToggleButton.selected = self.isShowingIpadResultsList;

        UIBarButtonItem *listBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.listViewToggleButton];

        UIBarButtonItem *currentLocationBarButton = self.tiledMapView.userLocationButton;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = @[listBarButton, flexibleSpace, currentLocationBarButton];
    } else {
        UIBarButtonItem *listBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageBarButtonList] style:UIBarButtonItemStylePlain target:self action:@selector(iphoneListButtonPressed)];
        UIBarButtonItem *currentLocationBarButton = self.tiledMapView.userLocationButton;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = @[currentLocationBarButton, flexibleSpace, listBarButton];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateAuthorizationStatus:) name:kLocationManagerDidUpdateAuthorizationStatusNotification object:nil];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self registerForKeyboardNotifications];
    self.searchBar.text = self.searchQuery;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - Setup

- (void)setupNavigationBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Insert the correct clear button image and uncomment the next line when ready
//    [searchBar setImage:[UIImage imageNamed:@""] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    
    self.searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    self.searchBarView.autoresizingMask = 0;
    self.searchBar.delegate = self;
    [self.searchBarView addSubview:self.searchBar];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.searchBarView
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.searchBar
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:0];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.searchBarView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.searchBar
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.searchBarView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.searchBar
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.searchBarView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.searchBar
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0];
    [self.searchBarView addConstraints:@[top, left, bottom, right]];
    self.navigationItem.titleView = self.searchBarView;
    
    self.bookmarksBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(bookmarksButtonPressed)];
    [self.navigationItem setRightBarButtonItem:self.bookmarksBarButton];
    [self.navigationItem setLeftBarButtonItem:[MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem];
    
    // Menu button set from MIT_MobileAppDelegate -- Capturing reference for search mode.
    self.menuBarButton = self.navigationItem.leftBarButtonItem;
}

- (void)setupMapView
{
    [self.tiledMapView setMapDelegate:self];
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
    
    [self setupMapBoundingBoxAnimated:NO];

    [self setupCalloutView];
}

- (void)setupCalloutView
{
    SMCalloutView *calloutView = [[SMCalloutView alloc] initWithFrame:CGRectZero];
    calloutView.contentViewMargin = 0;
    calloutView.anchorMargin = 39;
    calloutView.delegate = self;
    calloutView.permittedArrowDirection = SMCalloutArrowDirectionAny;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        calloutView.rightAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
    }
    
    self.calloutView = calloutView;
    
    self.tiledMapView.mapView.calloutView = self.calloutView;
}

- (void)setupTypeAheadTableView
{
    if (!self.typeAheadViewController) {
        self.typeAheadViewController = [[MITMapTypeAheadTableViewController alloc] initWithStyle:UITableViewStylePlain];
        self.typeAheadViewController.delegate = self;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.typeAheadViewController];
            self.typeAheadViewController.showsTitleHeader = YES;
        } else {
            [self addChildViewController:self.typeAheadViewController];
            self.typeAheadViewController.view.hidden = YES;
            self.typeAheadViewController.view.frame = CGRectZero;
            [self.view addSubview:self.typeAheadViewController.view];
            [self.typeAheadViewController didMoveToParentViewController:self];
        }
    }
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

#pragma mark - Private Methods

- (void)closePopoversAnimated:(BOOL)animated
{
    if (self.typeAheadPopoverController.isPopoverVisible) {
        [self.typeAheadPopoverController dismissPopoverAnimated:animated];
    }
    
    if (self.bookmarksPopoverController.isPopoverVisible) {
        [self.bookmarksPopoverController dismissPopoverAnimated:animated];
    }
}

#pragma mark - Button Actions

- (void)bookmarksButtonPressed
{
    MITMapBrowseContainerViewController *browseContainerViewController = [[MITMapBrowseContainerViewController alloc] initWithNibName:nil bundle:nil];
    [browseContainerViewController setDelegate:self];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browseContainerViewController];
    navigationController.navigationBarHidden = YES;
    navigationController.toolbarHidden = NO;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.bookmarksPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [self.bookmarksPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)ipadListButtonPressed
{
    if (self.isShowingIpadResultsList) {
        [self closeIpadResultsList];
    } else {
        [self openIpadResultsList];
    }
    self.listViewToggleButton.selected = self.isShowingIpadResultsList;
}

- (void)closeIpadResultsList
{
    if (self.isShowingIpadResultsList) {
        MITMartyResultsListViewController *resultsVC = [self resultsListViewController];
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            resultsVC.view.frame = CGRectMake(-320, resultsVC.view.frame.origin.y, resultsVC.view.frame.size.width, resultsVC.view.frame.size.height);
        } completion:nil];
        self.calloutView.constrainedInsets = UIEdgeInsetsZero;
        self.isShowingIpadResultsList = NO;
    }
}

- (void)openIpadResultsList
{
    if (!self.isShowingIpadResultsList) {
        MITMartyResultsListViewController *resultsVC = [self resultsListViewController];
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            resultsVC.view.frame = CGRectMake(0, resultsVC.view.frame.origin.y, resultsVC.view.frame.size.width, resultsVC.view.frame.size.height);
        } completion:nil];
        self.calloutView.constrainedInsets = UIEdgeInsetsMake(0, resultsVC.view.frame.size.width, 0, 0);
        self.isShowingIpadResultsList = YES;
    }
}

- (void)iphoneListButtonPressed
{
    UINavigationController *resultsListNavigationController = [[UINavigationController alloc] initWithRootViewController:[self resultsListViewController]];
    [self presentViewController:resultsListNavigationController animated:YES completion:nil];
}

#pragma mark - Search Bar

- (void)closeSearchBar
{
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton animated:YES];
    [self.navigationItem setRightBarButtonItem:self.bookmarksBarButton animated:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
}

- (void)setSearchBarTextColor:(UIColor *)color
{
    // A public API would be preferable, but UIAppearance doesn't update unless you remove the view from superview and re-add, which messes with the display
    UITextField *searchBarTextField = [self.searchBar textField];
    searchBarTextField.textColor = color;
}

- (void)setSearchQueryType:(MITMapSearchQueryType)searchQueryType
{
    UIColor *searchBarTextColor = (searchQueryType == MITMapSearchQueryTypeText) ? [UIColor blackColor] : [UIColor mit_tintColor];
    [self setSearchBarTextColor:searchBarTextColor];
    _searchQueryType = searchQueryType;
}

#pragma mark - Map View

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    if ([self.places count] > 0) {
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in self.places)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        double inset = -zoomRect.size.width * 0.1;
        [self.mapView setVisibleMapRect:MKMapRectInset(zoomRect, inset, inset) animated:YES];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

#pragma mark - Places

- (void)setPlaces:(NSArray *)places
{
    [self setPlaces:places animated:NO];
}

- (void)setPlaces:(NSArray *)places animated:(BOOL)animated
{
    _places = places;
    [[self resultsListViewController] setPlaces:places];
    self.shouldRefreshAnnotationsOnNextMapRegionChange = YES;
    self.showFirstCalloutOnNextMapRegionChange = YES;
    [self setupMapBoundingBoxAnimated:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    self.category = nil;
    self.searchQuery = nil;
    self.searchQueryType = MITMapSearchQueryTypeText;
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

#pragma mark - Search Results

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.isKeyboardVisible = YES;

        [UIView performWithoutAnimation:^{
            self.typeAheadViewController.view.frame = self.view.bounds;
        }];

        self.typeAheadViewController.view.hidden = NO;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.isKeyboardVisible = NO;
        self.typeAheadViewController.view.hidden = YES;
    }
}

- (void)searchSuggestionsTimerFired:(NSTimer *)timer
{
    NSDictionary *userInfo = timer.userInfo;
    NSString *searchText = userInfo[kMITMapSearchSuggestionsTimerUserInfoKeySearchText];
    if (searchText) {
        [self updateSearchResultsForSearchString:searchText];
    }
}

- (void)updateSearchResultsForSearchString:(NSString *)searchString
{
    [self.typeAheadViewController updateResultsWithSearchTerm:searchString];
}

- (void)performSearchWithQuery:(NSString *)query
{
    self.searchQuery = query;
    [[MITMapModelController sharedController] addRecentSearch:query];
    [[MITMapModelController sharedController] searchMapWithQuery:query
                                                          loaded:^(NSArray *objects, NSError *error) {
                                                              if (objects) {
                                                                  [self setPlaces:objects animated:YES];
                                                              }
                                                          }];
}

- (void)getPlaceForObjectID:(NSString *)objectID
{
    [[MITMapModelController sharedController] getPlacesForObjectID:objectID loaded:^(NSArray *objects, NSError *error) {
        if (objects) {
            [self setPlaces:objects animated:YES];
            MITMapPlace *place = objects.firstObject;
            if (place) {
                [[MITMapModelController sharedController] addRecentSearch:place.name];
            }
        }
    }];
}

- (void)setPlacesWithQuery:(NSString *)query
{
    [self performSearchWithQuery:query];
    self.category = nil;
    self.searchBar.text = query;
    self.searchQueryType = MITMapSearchQueryTypeText;
}

- (void)setPlacesWithPlace:(MITMapPlace *)place
{
    [[MITMapModelController sharedController] addRecentSearch:place];
    self.searchQuery = nil;
    self.category = nil;
    [self setPlaces:@[place] animated:YES];
    self.searchBar.text = place.name;
    self.searchQueryType = MITMapSearchQueryTypePlace;
}

- (void)setPlacesWithCategory:(MITMapCategory *)category
{
    [[MITMapModelController sharedController] addRecentSearch:category];
    self.category = category;
    self.searchQuery = nil;
    NSArray *places = category.allPlaces;
    [self setPlaces:places animated:YES];
    self.searchBar.text = category.name;
    self.searchQueryType = MITMapSearchQueryTypeCategory;
}

- (void)pushDetailViewControllerForPlace:(MITMapPlace *)place
{
    MITMapPlaceDetailViewController *detailVC = [[MITMapPlaceDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.place = place;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)showCalloutForPlace:(MITMapPlace *)place
{
    if ([self.places containsObject:place]) {
        [self.mapView selectAnnotation:place animated:YES];
    }
}

- (void)showTypeAheadPopover
{
    self.typeAheadPopoverController.delegate = self;
    [self.typeAheadPopoverController presentPopoverFromRect:CGRectMake(self.searchBar.bounds.size.width / 2, self.searchBar.bounds.size.height, 1, 1) inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (MITMartyResultsListViewController *)resultsListViewController
{
    static MITMartyResultsListViewController *resultsListViewController;
    if (!resultsListViewController) {
        resultsListViewController = [[MITMartyResultsListViewController alloc] initWithPlaces:self.places];
        resultsListViewController.delegate = self;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            resultsListViewController.hideDetailButton = YES;
            resultsListViewController.view.frame = CGRectMake(-320, 0, 320, self.view.bounds.size.height);
            resultsListViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            self.isShowingIpadResultsList = NO;
            
            [self addChildViewController:resultsListViewController];
            [resultsListViewController beginAppearanceTransition:YES animated:NO];
            [self.view addSubview:resultsListViewController.view];
            
            [resultsListViewController endAppearanceTransition];
            [resultsListViewController didMoveToParentViewController:self];
        }
    }
    
    switch (self.searchQueryType) {
        case MITMapSearchQueryTypeText: {
            [resultsListViewController setTitleWithSearchQuery:self.searchQuery];
            break;
        }
        case MITMapSearchQueryTypePlace: {
            MITMapPlace *place = [self.places firstObject];
            [resultsListViewController setTitle:place.name];
            break;
        }
        case MITMapSearchQueryTypeCategory: {
            [resultsListViewController setTitle:self.category.name];
            break;
        }
        default:
            break;
    }
    
    return resultsListViewController;
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self resizeAndAlignSearchBar];
    
    if (!self.isKeyboardVisible && [self.searchBar isFirstResponder] && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        CGFloat tableViewHeight = self.view.frame.size.height;
        self.typeAheadViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, tableViewHeight);
    }
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self showTypeAheadPopover];
    } else {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.searchBar setShowsCancelButton:YES animated:YES];
        [self resizeAndAlignSearchBar];
        
        CGFloat tableViewHeight = self.view.frame.size.height;
        self.typeAheadViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, tableViewHeight);
        self.typeAheadViewController.view.hidden = NO;
    }
    
    [self updateSearchResultsForSearchString:self.searchQuery];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self closeSearchBar];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.typeAheadViewController.view.hidden = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
    self.searchQueryType = MITMapSearchQueryTypeText;
    [self performSearchWithQuery:searchBar.text];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (self.searchQueryType != MITMapSearchQueryTypeText) {
        searchBar.text = text;
        self.searchQueryType = MITMapSearchQueryTypeText;
    }
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchSuggestionsTimer invalidate];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (searchText) {
        userInfo[kMITMapSearchSuggestionsTimerUserInfoKeySearchText] = searchText;
    }
    self.searchSuggestionsTimer = [NSTimer scheduledTimerWithTimeInterval:kMITMapSearchSuggestionsTimerWaitDuration
                                                                   target:self
                                                                 selector:@selector(searchSuggestionsTimerFired:)
                                                                 userInfo:userInfo
                                                                  repeats:NO];
    
    if (searchBar.isFirstResponder) {
        if (!self.typeAheadPopoverController.popoverVisible) {
            [self showTypeAheadPopover];
        }
    } else {
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

- (void)resizeAndAlignSearchBar
{
    // Force size to width of view
    CGRect bounds = self.searchBarView.bounds;
    bounds.size.width = CGRectGetWidth(self.view.bounds);
    self.searchBarView.bounds = bounds;
}

#pragma mark - In App Linking

- (void)handleInternalURLQuery:(NSString *)query forQueryEndpoint:(NSString *)queryEndpoint
{
    if ([queryEndpoint isEqualToString:@"search"]) {
        query = [query stringByRemovingPercentEncoding];
        [self performSearchWithQuery:query];
        self.searchQuery = query;
    }
    else if ([queryEndpoint isEqualToString:@"places"]) {
        [self getPlaceForObjectID:query];
        // Remove the `object-` prefix for the user visible string
        NSRange range = [query rangeOfString:@"object-"];
        query = [query substringFromIndex:range.length];
        self.searchQuery = query;
    }
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

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self presentIPadCalloutForAnnotationView:view];
        } else {
            [self presentIPhoneCalloutForAnnotationView:view];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]){
        [self.calloutView dismissCalloutAnimated:YES];
        self.currentlySelectedPlace = nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITMapPlace *place = view.annotation;
        [self pushDetailViewControllerForPlace:place];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.shouldRefreshAnnotationsOnNextMapRegionChange) {
        [self refreshPlaceAnnotations];
        self.shouldRefreshAnnotationsOnNextMapRegionChange = NO;
    }
    
    if (self.showFirstCalloutOnNextMapRegionChange) {
        if (self.places.count > 0) {
            [self showCalloutForPlace:[self.places firstObject]];
        }
        
        self.showFirstCalloutOnNextMapRegionChange = NO;
    }
}

#pragma mark - Callout View

- (void)presentIPadCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMapPlace *place = annotationView.annotation;
    self.currentlySelectedPlace = place;
    MITMapPlaceDetailViewController *detailVC = [[MITMapPlaceDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.place = place;
    
    detailVC.view.frame = CGRectMake(0, 0, 295, 500);
    
    SMCalloutView *calloutView = self.calloutView;
    calloutView.contentView = detailVC.view;
    calloutView.contentView.clipsToBounds = YES;
    calloutView.calloutOffset = annotationView.calloutOffset;
        
    self.calloutView = calloutView;
    self.calloutViewController = detailVC;
    
    [calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
    
    // We have to adjust the frame of the content view once its in the view hierarchy, because its constraints don't play nicely with SMCalloutView
    if (calloutView.currentArrowDirection == SMCalloutArrowDirectionUp) {
        detailVC.view.frame = CGRectMake(0, 15, 320, 496);
    }
    else {
        detailVC.view.frame = CGRectMake(0, 2, 320, 496);
    }
}

- (void)presentIPhoneCalloutForAnnotationView:(MKAnnotationView *)annotationView
{
    MITMapPlace *place = annotationView.annotation;
    
    self.currentlySelectedPlace = place;
    self.calloutView.title = place.title;
    self.calloutView.subtitle = place.subtitle;
    self.calloutView.calloutOffset = annotationView.calloutOffset;

    [self.calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
}

#pragma mark - SMCalloutViewDelegate Methods

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset
{
    MKMapView *mapView = self.mapView;
    CGPoint adjustedCenter = CGPointMake(-offset.width + mapView.bounds.size.width * 0.5,
                                         -offset.height + mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [mapView convertPoint:adjustedCenter toCoordinateFromView:mapView];
    [mapView setCenterCoordinate:newCenter animated:YES];
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self pushDetailViewControllerForPlace:self.currentlySelectedPlace];
    }
}

- (BOOL)calloutViewShouldHighlight:(SMCalloutView *)calloutView
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return YES;
    }
    return NO;
}

#pragma mark - MITMapResultsListViewControllerDelegate

- (void)resultsListViewController:(MITMartyResultsListViewController *)viewController didSelectPlace:(MITMapPlace *)place
{
    [self showCalloutForPlace:place];
}

#pragma mark - MITMapPlaceSelectionDelegate

- (void)placeSelectionViewController:(UIViewController <MITMapPlaceSelector >*)viewController didSelectPlace:(MITMapPlace *)place
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self setPlacesWithPlace:place];
            }];
        } else {
            [self setPlacesWithPlace:place];
            [self.searchBar resignFirstResponder];
        }
    } else {
        [self.searchBar resignFirstResponder];
        [self closePopoversAnimated:YES];
        [self setPlacesWithPlace:place];
    }
}

- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector> *)viewController didSelectCategory:(MITMapCategory *)category
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self setPlacesWithCategory:category];
            }];
        } else {
            [self setPlacesWithCategory:category];
            [self.searchBar resignFirstResponder];
        }
    } else {
        [self.searchBar resignFirstResponder];
        [self closePopoversAnimated:YES];
        [self setPlacesWithCategory:category];
    }
}

- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector> *)viewController didSelectQuery:(NSString *)query
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self setPlacesWithQuery:query];
            }];
        } else {
            [self setPlacesWithQuery:query];
            [self.searchBar resignFirstResponder];
        }
    } else {
        [self.searchBar resignFirstResponder];
        [self closePopoversAnimated:YES];
        [self setPlacesWithQuery:query];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.typeAheadPopoverController) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - Location Notifications

- (void)locationManagerDidUpdateAuthorizationStatus:(NSNotification *)notification
{
    self.mapView.showsUserLocation = [MITLocationManager locationServicesAuthorized];
}

#pragma mark - Getters | Setters

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _searchBar.placeholder = @"Search Marty";
    }
    return _searchBar;
}

@end
