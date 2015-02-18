#import "MITMartyPadHomeViewController.h"
#import "MITMartyResourceDataSource.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITSlidingViewController.h"

#import "MITMartyResourceDataSource.H"
#import "MITMartyResource.h"
#import "MITMartyResourcesTableViewController.h"
#import "MITCoreDataController.h"
#import "MITMartyRecentSearchController.h"

#import "MITMartyMapViewController.h"

@interface MITMartyPadHomeViewController () <UISearchBarDelegate, UIPopoverControllerDelegate, MITMartyResourcesTableViewControllerDelegate, MITMapPlaceSelectionDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UIButton *listViewToggleButton;
@property (nonatomic) BOOL searchBarShouldBeginEditing;
@property (nonatomic, strong) MITMartyRecentSearchController *searchViewController;
@property (nonatomic, strong) UIPopoverController *typeAheadPopoverController;
@property (nonatomic) BOOL isShowingIpadResultsList;

@property (nonatomic, strong) UIPopoverController *bookmarksPopoverController;

@property (nonatomic, copy) NSString *searchQuery;
@property (nonatomic, strong) MITMapCategory *category;
@property (nonatomic, strong) UIView *searchBarView;
@property (nonatomic) BOOL isKeyboardVisible;

@property (nonatomic, strong) MITMartyResourceDataSource *dataSource;
@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) MITMartyResourcesTableViewController *resourcesTableViewController;
@property (strong, nonatomic) MITMartyResourceDataSource *modelController;
@property (nonatomic, strong) MITMartyMapViewController *mapViewController;

@end

@implementation MITMartyPadHomeViewController

#pragma mark - properties
- (MITMartyResourceDataSource *)modelController
{
    if(!_modelController) {
        MITMartyResourceDataSource *modelController = [[MITMartyResourceDataSource alloc] init];
        _modelController = modelController;
    }
    return _modelController;
}

- (MITMartyMapViewController *)mapViewController
{
    if(!_mapViewController) {
        MITMartyMapViewController *mapViewController = [[MITMartyMapViewController alloc] init];
        _mapViewController = mapViewController;
    }
    return _mapViewController;
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

#pragma mark Public Properties
- (NSArray*)resources
{
    __block NSArray *resourceObjects = nil;
    [self.managedObjectContext performBlockAndWait:^{
        resourceObjects = [self.managedObjectContext transferManagedObjects:self.dataSource.resources];
    }];
    
    return resourceObjects;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    [self setupRecentSearchTableView];
    [self setupMapViewController];
    
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
        UIBarButtonItem *currentLocationBarButton = self.mapViewController.userLocationButton;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = @[listBarButton, flexibleSpace, currentLocationBarButton];
 
    } else {
        
        UIBarButtonItem *listBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageBarButtonList] style:UIBarButtonItemStylePlain target:self action:@selector(iphoneListButtonPressed)];
        UIBarButtonItem *currentLocationBarButton = self.mapViewController.userLocationButton;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = @[currentLocationBarButton, flexibleSpace, listBarButton];
        
    }
    
    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
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
    self.searchBarView.autoresizingMask = UIViewAutoresizingNone;
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
    
    [self.navigationItem setLeftBarButtonItem:[MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem];
    
    // Menu button set from MIT_MobileAppDelegate -- Capturing reference for search mode.
    self.menuBarButton = self.navigationItem.leftBarButtonItem;
}

- (void)setupRecentSearchTableView
{
    if (!self.searchViewController) {
        self.searchViewController = [[MITMartyRecentSearchController alloc] initWithStyle:UITableViewStylePlain];
        self.searchViewController.delegate = self;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.searchViewController];

            self.typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        } else {
            [self addChildViewController:self.searchViewController];
            self.searchViewController.view.hidden = YES;
            self.searchViewController.view.frame = CGRectZero;
            [self.view addSubview:self.searchViewController.view];
            [self.searchViewController didMoveToParentViewController:self];
        }
    }
}

- (void)setupMapViewController
{
    self.mapViewController.view.frame = self.view.frame;
    self.mapViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);

    [self addChildViewController:self.mapViewController];
    [self.view addSubview:self.mapViewController.view];
    [self.mapViewController didMoveToParentViewController:self];
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

//  BOOKSMARKS ARE NOT NEEDED IN THIS VERSION
/*
- (void)bookmarksButtonPressed
{
    MITMapBrowseContainerViewController *browseContainerViewController = [[MITMapBrowseContainerViewController alloc] init];
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
 */

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
        MITMartyResourcesTableViewController *resultsVC = [self resourcesTableViewController];
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            resultsVC.view.frame = CGRectMake(-320, resultsVC.view.frame.origin.y, resultsVC.view.frame.size.width, resultsVC.view.frame.size.height);
        } completion:nil];
        self.mapViewController.calloutView.constrainedInsets = UIEdgeInsetsZero;
        self.isShowingIpadResultsList = NO;
    }
}

- (void)openIpadResultsList
{
    if (!self.isShowingIpadResultsList) {
        MITMartyResourcesTableViewController *resultsVC = [self resourcesTableViewController];
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            resultsVC.view.frame = CGRectMake(0, resultsVC.view.frame.origin.y, resultsVC.view.frame.size.width, resultsVC.view.frame.size.height);
        } completion:nil];
        self.mapViewController.calloutView.constrainedInsets = UIEdgeInsetsMake(0, resultsVC.view.frame.size.width, 0, 0);
        self.isShowingIpadResultsList = YES;
    }
}

- (void)iphoneListButtonPressed
{
    UINavigationController *resultsListNavigationController = [[UINavigationController alloc] initWithRootViewController:[self resourcesTableViewController]];
    [self presentViewController:resultsListNavigationController animated:YES completion:nil];
}

#pragma mark - Search Bar

- (void)closeSearchBar
{
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton animated:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
}

- (void)setSearchBarTextColor:(UIColor *)color
{
    // A public API would be preferable, but UIAppearance doesn't update unless you remove the view from superview and re-add, which messes with the display
    UITextField *searchBarTextField = [self.searchBar textField];
    searchBarTextField.textColor = color;
}

#pragma mark - Places

- (void)setResources:(NSArray *)resources
{
    [self setResources:resources animated:NO];
}

- (void)setResources:(NSArray *)resources animated:(BOOL)animated
{
    [[self resourcesTableViewController] setResources:resources];
    
    [[self mapViewController] setResources:resources];
    
    [self.mapViewController resourcesChanged:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    self.category = nil;
    self.searchQuery = nil;
    [self setResources:nil animated:animated];
}


#pragma mark - Search Results

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.isKeyboardVisible = YES;

        [UIView performWithoutAnimation:^{
            self.searchViewController.view.frame = self.view.bounds;
        }];

        self.searchViewController.view.hidden = NO;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.isKeyboardVisible = NO;
        self.searchViewController.view.hidden = YES;
    }
}

- (void)updateSearchResultsForSearchString:(NSString *)searchString
{
    [self.searchViewController filterResultsUsingString:searchString];
}

- (void)performSearchWithQuery:(NSString *)query
{
    self.searchQuery = query;

    NSError *error = nil;
    [self.modelController addRecentSearchItem:query error:error];
    
    MITMartyResourceDataSource *dataSource = [[MITMartyResourceDataSource alloc] init];
    self.dataSource = dataSource;
    [dataSource resourcesWithQuery:query completion:^(MITMartyResourceDataSource *dataSource, NSError *error) {
        if (error) {
            DDLogWarn(@"Error: %@",error);
        } else {
            [self.managedObjectContext performBlockAndWait:^{
                [self.managedObjectContext reset];
                
                [self.resources enumerateObjectsUsingBlock:^(MITMartyResource *resource, NSUInteger idx, BOOL *stop) {
                    DDLogVerbose(@"Got resource with name: %@ [%@]",resource.name, resource.identifier);
                }];
                [self setResources:self.resources animated:YES];

                
            }];
        }
    }];
}

- (void)setResourcesWithQuery:(NSString *)query
{
    [self performSearchWithQuery:query];
    self.category = nil;
    self.searchBar.text = query;
}

- (void)setResourcesWithResource:(MITMartyResource *)resource
{
    self.searchQuery = nil;
    self.category = nil;
    
    [self setResources:@[resource] animated:YES];
    self.searchBar.text = resource.name;
}

- (void)showTypeAheadPopover
{
    self.typeAheadPopoverController.delegate = self;
    [self.typeAheadPopoverController presentPopoverFromRect:CGRectMake(self.searchBar.bounds.size.width / 2, self.searchBar.bounds.size.height, 1, 1) inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (MITMartyResourcesTableViewController *)resourcesTableViewController
{
    if (!_resourcesTableViewController) {
        
        MITMartyResourcesTableViewController *resourcesTableViewController = [[MITMartyResourcesTableViewController alloc] init];
        resourcesTableViewController.resources = self.resources;
        resourcesTableViewController.delegate = self;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            resourcesTableViewController.view.frame = CGRectMake(-320, 0, 320, self.view.bounds.size.height);
            resourcesTableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            self.isShowingIpadResultsList = NO;
            
            [self addChildViewController:resourcesTableViewController];
            [resourcesTableViewController beginAppearanceTransition:YES animated:NO];
            [self.view addSubview:resourcesTableViewController.view];
            
            [resourcesTableViewController endAppearanceTransition];
            [resourcesTableViewController didMoveToParentViewController:self];
            _resourcesTableViewController = resourcesTableViewController;
        }
    }
    
    return _resourcesTableViewController;
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self resizeAndAlignSearchBar];
    
    if (!self.isKeyboardVisible && [self.searchBar isFirstResponder] && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        CGFloat tableViewHeight = self.view.frame.size.height;
        self.searchViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, tableViewHeight);
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
        self.searchViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, tableViewHeight);
        self.searchViewController.view.hidden = NO;
    }
    
    [self updateSearchResultsForSearchString:self.searchQuery];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self closeSearchBar];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.searchViewController.view.hidden = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
    [self performSearchWithQuery:searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
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


#pragma mark - MITMartyResourcesTableViewControllerDelegate

- (void)resourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController didSelectResource:(MITMartyResource *)resource
{
    [self.mapViewController showCalloutForResource:resource];
}

#pragma mark - MITMartyResourcesTableViewControllerDelegate

- (void)placeSelectionViewController:(UIViewController <MITMapPlaceSelector >*)viewController didSelectResource:(MITMartyResource *)resource
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self setResourcesWithResource:resource];
            }];
        } else {
            [self setResourcesWithResource:resource];
            [self.searchBar resignFirstResponder];
        }
    } else {
        [self.searchBar resignFirstResponder];
        [self closePopoversAnimated:YES];
        [self setResourcesWithResource:resource];
    }
}

- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector> *)viewController didSelectQuery:(NSString *)query
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self setResourcesWithQuery:query];
            }];
        } else {
            [self setResourcesWithQuery:query];
            [self.searchBar resignFirstResponder];
        }
    } else {
        [self.searchBar resignFirstResponder];
        [self closePopoversAnimated:YES];
        [self setResourcesWithQuery:query];
    }
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.typeAheadPopoverController) {
        [self.searchBar resignFirstResponder];
    }
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
