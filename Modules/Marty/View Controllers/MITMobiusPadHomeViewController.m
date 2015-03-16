#import "MITMobiusPadHomeViewController.h"
#import "MITMobiusResourceDataSource.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITSlidingViewController.h"

#import "MITMobiusResourceDataSource.H"
#import "MITMobiusResource.h"
#import "MITMobiusResourcesTableViewController.h"
#import "MITCoreDataController.h"
#import "MITMartyRecentSearchController.h"

#import "MITMobiusMapViewController.h"

@interface MITMobiusPadHomeViewController () <UISearchBarDelegate, UIPopoverControllerDelegate, MITMobiusResourcesTableViewControllerDelegate, MITMapPlaceSelectionDelegate>

@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UIButton *listViewToggleButton;

@property (nonatomic,getter=isSearching) BOOL searching;

@property (nonatomic, strong) MITMartyRecentSearchController *searchViewController;
@property (nonatomic, strong) UIPopoverController *typeAheadPopoverController;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic) BOOL searchBarShouldBeginEditing;
@property (nonatomic) BOOL searchBarShouldEndEditing;

@property (nonatomic,getter=isResultsListHidden) BOOL resultsListHidden;

@property (nonatomic, strong) UIPopoverController *bookmarksPopoverController;

@property (nonatomic, copy) NSString *searchQuery;
@property (nonatomic, strong) UIView *searchBarView;
@property (nonatomic) BOOL isKeyboardVisible;

@property (nonatomic, strong) MITMobiusResourceDataSource *dataSource;

@property (nonatomic, strong) MITMobiusResourcesTableViewController *resourcesTableViewController;
@property (nonatomic, strong) MITMobiusMapViewController *mapViewController;

@end

@implementation MITMobiusPadHomeViewController

#pragma mark - properties
- (MITMobiusMapViewController *)mapViewController
{
    if(!_mapViewController) {
        MITMobiusMapViewController *mapViewController = [[MITMobiusMapViewController alloc] init];
        _mapViewController = mapViewController;
    }
    return _mapViewController;
}

#pragma mark - Init
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchBarShouldBeginEditing = YES;
        _searchBarShouldEndEditing = YES;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _searchBarShouldBeginEditing = YES;
        _searchBarShouldEndEditing = YES;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    MITMobiusResourceDataSource *dataSource = [[MITMobiusResourceDataSource alloc] init];
    self.dataSource = dataSource;
    
    [self setupNavigationBar];
    [self setupRecentSearchTableView];
    [self setupMapViewController];
    
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

    UIBarButtonItem *listBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.listViewToggleButton];
    UIBarButtonItem *currentLocationBarButton = self.mapViewController.userLocationButton;
    self.toolbarItems = @[listBarButton, [UIBarButtonItem flexibleSpace], currentLocationBarButton];
    
    [self setResultsListHidden:YES animated:NO];
    self.listViewToggleButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    [self.navigationItem setHidesBackButton:YES animated:NO];
    self.searchBar.text = self.searchQuery;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
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

#pragma mark - Properties
- (BOOL)searchBarShouldEndEditing
{
    return (_searchBarShouldEndEditing && [self typeAheadPopoverControllerIsVisible]);
}

#pragma mark - Private Methods
- (BOOL)typeAheadPopoverControllerIsLoaded
{
    return (_typeAheadPopoverController != nil);
}

- (BOOL)typeAheadPopoverControllerIsVisible
{
    return ([self typeAheadPopoverControllerIsLoaded] && self.typeAheadPopoverController.isPopoverVisible);
}

- (UIPopoverController*)typeAheadPopoverController
{
    if (![self typeAheadPopoverControllerIsLoaded]) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.searchViewController];
        
        _typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        _typeAheadPopoverController.delegate = self;
        
        NSMutableArray *passthroughViews = [[NSMutableArray alloc] init];
        [passthroughViews addObject:navigationController.view];
        [passthroughViews addObject:navigationController.navigationBar];
        
        if (!self.navigationController.isNavigationBarHidden) {
            [passthroughViews addObject:self.navigationController.navigationBar];
        }
        
        _typeAheadPopoverController.passthroughViews = passthroughViews;
        
        UIUserInterfaceIdiom interfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
        switch (interfaceIdiom) {
            case UIUserInterfaceIdiomPad: {
                CGFloat contentWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame) / 3.0;
                _typeAheadPopoverController.contentViewController.preferredContentSize = CGSizeMake(contentWidth, 0);
                _typeAheadPopoverController.contentViewController.view.frame = CGRectMake(0, 0, contentWidth, 0);
            } break;
                
            default: {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIUserInterfaceIdiom type" userInfo:nil];
            }
        }
        
    }
    
    return _typeAheadPopoverController;
}

- (void)closePopoversAnimated:(BOOL)animated
{
    if ([self typeAheadPopoverControllerIsVisible]) {
        [self.typeAheadPopoverController dismissPopoverAnimated:animated];
    }
    
    if ([self.bookmarksPopoverController isPopoverVisible]) {
        [self.bookmarksPopoverController dismissPopoverAnimated:animated];
    }
}

#pragma mark - Button Actions
- (void)ipadListButtonPressed
{
    [self setResultsListHidden:!self.isResultsListHidden animated:YES];
}

- (void)iphoneListButtonPressed
{
    UINavigationController *resultsListNavigationController = [[UINavigationController alloc] initWithRootViewController:[self resourcesTableViewController]];
    [self presentViewController:resultsListNavigationController animated:YES completion:nil];
}

#pragma mark - Search Bar

- (void)closeSearchBar
{
    [self.searchBar resignFirstResponder];
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton animated:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self closePopoversAnimated:YES];
}

- (void)setSearchBarTextColor:(UIColor *)color
{
    // A public API would be preferable, but UIAppearance doesn't update unless you remove the view from superview and re-add, which messes with the display
    UITextField *searchBarTextField = [self.searchBar textField];
    searchBarTextField.textColor = color;
}

#pragma mark - Places
- (void)clearPlacesAnimated:(BOOL)animated
{
    self.searchQuery = nil;
    
    [self.mapViewController setResources:nil animated:animated];
    self.resourcesTableViewController.resources = nil;
}


#pragma mark - Search Results
- (void)updateSearchResultsForSearchString:(NSString *)searchString
{
    if (self.isSearching) {
        [self.searchViewController filterResultsUsingString:searchString];
        if ([searchString length] == 0) {
            self.searchQuery = nil;
        }
    }
}

- (void)performSearchWithQuery:(NSString *)query completion:(void(^)(BOOL success))completion
{
    if ([query length]) {
        self.searchQuery = query;
        
        [self.dataSource resourcesWithQuery:query completion:^(MITMobiusResourceDataSource *dataSource, NSError *error) {
            [dataSource addRecentSearchItem:query error:nil];
            
            if (error) {
                DDLogWarn(@"Error: %@",error);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (completion) {
                        completion(NO);
                    }
                }];
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (completion) {
                        completion(YES);
                    }
                }];
            }
        }];
    } else {
        self.searchQuery = nil;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (completion) {
                completion(YES);
            }
        }];
    }
}

- (void)setResourcesWithQuery:(NSString *)query
{
    self.searchBar.text = query;
    
    [self performSearchWithQuery:query completion:^(BOOL success) {
        NSArray *resources = nil;
        if (success) {
            resources = self.dataSource.resources;
        }
        
        [self setResources:resources animated:YES];
    }];
}

- (void)setResourcesWithResource:(MITMobiusResource *)resource
{
    self.searchBar.text = resource.name;
    [self setResources:@[resource] animated:YES];
}

- (void)setResources:(NSArray*)resources animated:(BOOL)animated
{
    self.resourcesTableViewController.resources = resources;
    [self.mapViewController setResources:resources animated:animated];
    
    // TODO: Change to show a message in the table view that there
    // are no results to show (and don't prevent the user from showing/hiding
    // the view)
    if ([resources count] == 0) {
        [self setResultsListHidden:YES animated:animated];
        self.listViewToggleButton.enabled = NO;
    } else {
        self.listViewToggleButton.enabled = YES;
    }
}

- (void)_showTypeAheadPopover:(BOOL)animated
{
    [self.searchViewController filterResultsUsingString:self.searchQuery];
    CGSize popoverFrameSize = [self.typeAheadPopoverController.contentViewController.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // Make sure we are presenting a valid size. All popovers must have:
    // {(height,width) | height > 0, width >= 320, width <= 600} on iOS 8,
    // but there should be something visible, so start the height out at 1/3 the superview's height
    // (picked arbitrarily)
    // (bskinner - 2015.03.04)
    popoverFrameSize.height = CGRectGetHeight(self.view.bounds) / 3.0;
    popoverFrameSize.width = MIN(600., MAX(popoverFrameSize.width, 320.));
    self.typeAheadPopoverController.contentViewController.preferredContentSize = popoverFrameSize;
    
    CGRect popoverFrame = CGRectZero;
    popoverFrame.origin.y = CGRectGetMinY(self.view.bounds);
    popoverFrame.origin.x = CGRectGetMidX(self.view.bounds);
    popoverFrame = CGRectOffset(popoverFrame, -(CGRectGetWidth(popoverFrame) / 2.0), 0);
    [self.typeAheadPopoverController presentPopoverFromRect:popoverFrame
                                       inView:self.view
                     permittedArrowDirections:UIPopoverArrowDirectionUp
                                     animated:YES];
}

- (MITMobiusResourcesTableViewController *)resourcesTableViewController
{
    if (!_resourcesTableViewController) {
        MITMobiusResourcesTableViewController *resourcesTableViewController = [[MITMobiusResourcesTableViewController alloc] init];
        resourcesTableViewController.delegate = self;
        
        resourcesTableViewController.view.frame = CGRectMake(0., 0, 320., self.view.bounds.size.height);
        resourcesTableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        resourcesTableViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        
        [self addChildViewController:resourcesTableViewController];
        [resourcesTableViewController beginAppearanceTransition:YES animated:NO];
        [self.view addSubview:resourcesTableViewController.view];
        
        [resourcesTableViewController endAppearanceTransition];
        [resourcesTableViewController didMoveToParentViewController:self];
        _resourcesTableViewController = resourcesTableViewController;
    }
    
    return _resourcesTableViewController;
}

- (void)setResultsListHidden:(BOOL)resultsListHidden
{
    [self setResultsListHidden:resultsListHidden animated:NO];
}

- (void)setResultsListHidden:(BOOL)resultsListHidden animated:(BOOL)animated
{
    _resultsListHidden = resultsListHidden;
    
    if (_resultsListHidden) {
        self.listViewToggleButton.selected = NO;
    } else {
        self.listViewToggleButton.selected = YES;
    }
    
    NSTimeInterval duration = (animated ? 0.33 : 0.);
    [UIView animateWithDuration:duration
                          delay:0.
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         UIEdgeInsets mapInsets = UIEdgeInsetsZero;
                         CGAffineTransform transform = CGAffineTransformIdentity;
                         if (_resultsListHidden) {
                             CGFloat offset = CGRectGetMaxX(self.resourcesTableViewController.view.frame);
                             transform = CGAffineTransformMakeTranslation(-offset, 0);
                         } else {
                             mapInsets = UIEdgeInsetsMake(0, CGRectGetWidth(self.resourcesTableViewController.view.frame), 0, 0);
                         }
                         
                         self.resourcesTableViewController.view.transform = transform;
                         
                         self.mapViewController.calloutView.externalInsets = mapInsets;
                         self.mapViewController.mapEdgeInsets = mapInsets;
                         [self.mapViewController recenterOnVisibleResources:YES];
                     } completion:nil];
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
    [self setSearching:YES animated:YES];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.searchBar setShowsCancelButton:YES animated:YES];
        [self resizeAndAlignSearchBar];
        
        CGFloat tableViewHeight = self.view.frame.size.height;
        self.searchViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, tableViewHeight);
        self.searchViewController.view.hidden = NO;
    }
    
    [self updateSearchResultsForSearchString:searchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self setSearching:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self setResourcesWithQuery:searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateSearchResultsForSearchString:searchBar.text];
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

- (void)resourcesTableViewController:(MITMobiusResourcesTableViewController *)tableViewController didSelectResource:(MITMobiusResource *)resource
{
    [self.mapViewController showCalloutForResource:resource];
}

#pragma mark - MITMartyResourcesTableViewControllerDelegate

- (void)placeSelectionViewController:(UIViewController <MITMapPlaceSelector >*)viewController didSelectResource:(MITMobiusResource *)resource
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
        self.typeAheadPopoverController = nil;
        [self setSearching:NO animated:YES];
    }
}


#pragma mark - Getters | Setters
- (void)setSearching:(BOOL)searching
{
    [self setSearching:searching animated:NO];
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated
{
    if (_searching != searching) {
        _searching = searching;
        
        UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
        switch (interfaceIdiom) {
            case UIUserInterfaceIdiomPad: {
                [self _updateSearchingForPadIdiom:animated];
            } break;
    
            default: {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unsupported UIUserInterfaceIdiom type" userInfo:nil];
            }
        }
    }
}

- (void)_updateSearchingForPadIdiom:(BOOL)animated
{
    if (self.isSearching) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        [self.searchBar becomeFirstResponder];
        [self.searchBar setShowsCancelButton:YES animated:animated];
        [self _showTypeAheadPopover:animated];
    } else {
        [self.searchBar resignFirstResponder];
        [self.searchBar setShowsCancelButton:NO animated:animated];
        [self.typeAheadPopoverController dismissPopoverAnimated:animated];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
}

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
