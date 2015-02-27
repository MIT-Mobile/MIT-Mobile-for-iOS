#import "MITMartyRootPhoneViewController.h"
#import "MITMartyResourceDataSource.h"
#import "MITMartyModel.h"
#import "MITMartyResourcesTableViewController.h"
#import "MITMartyDetailTableViewController.h"
#import "MITSlidingViewController.h"
#import "MITCalloutMapView.h"

#import "MITMartyMapViewController.h"
#import "MITMartyRecentSearchController.h"
#import "MITMapPlaceSelector.h"

#import "DDLog.h"
#import "MITAdditions.h"

static NSTimeInterval MITMartyRootPhoneDefaultAnimationDuration = 0.33;

typedef NS_ENUM(NSInteger, MITMartyRootViewControllerState) {
    MITMartyRootViewControllerStateInitial = 0,
    MITMartyRootViewControllerStateSearch,
    MITMartyRootViewControllerStateNoResults,
    MITMartyRootViewControllerStateResults,
};

@interface MITMartyRootPhoneViewController () <MITMartyResourcesTableViewControllerDelegate,MITMapPlaceSelectionDelegate,UISearchDisplayDelegate,UISearchBarDelegate>

// These are currently strong since, if they are weak,
// they are being released during the various animations and
// wreaking havoc. Guessing it's either in the updateViewConstraints
// or the toggle animation.
// TODO: Figure out exactly where the 'weak' semantics go off the rails
// (bskinner 2015.02.25)
@property(nonatomic,strong) IBOutlet NSLayoutConstraint *mapHeightConstraint;
@property(nonatomic,strong) IBOutlet NSLayoutConstraint *defaultMapHeightConstraint;

@property(nonatomic) MITMartyRootViewControllerState currentState;
@property(nonatomic,getter=isMapFullScreen) BOOL mapFullScreen;


@property(nonatomic,strong) MITMartyResourceDataSource *dataSource;

@property(nonatomic,weak) MITMartyResourcesTableViewController *resourcesTableViewController;
@property(nonatomic,weak) MITMartyMapViewController *mapViewController;
@property(nonatomic,weak) UITapGestureRecognizer *fullScreenMapGesture;

@property(nonatomic,weak) MITMartyRecentSearchController *typeAheadViewController;
@property(nonatomic,weak) UIView *searchBarContainer;
@property(nonatomic,weak) UISearchBar *searchBar;
@property(nonatomic,getter=isSearching) BOOL searching;
@property(nonatomic,strong) NSTimer *searchSuggestionsTimer;

@end

@implementation MITMartyRootPhoneViewController {
    CGFloat _mapVerticalOffset;
    CGAffineTransform _previousMapTransform;
}

@synthesize resourcesTableViewController = _resourcesTableViewController;
@synthesize mapViewController = _mapViewController;
@synthesize typeAheadViewController = _typeAheadViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:YES];
    }

    self.contentContainerView.hidden = YES;

    _previousMapTransform = CGAffineTransformIdentity;
    self.mapViewContainer.userInteractionEnabled = NO;

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleFullScreenMapGesture:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.contentContainerView addGestureRecognizer:gestureRecognizer];
    self.fullScreenMapGesture = gestureRecognizer;

    UIImage *image = [UIImage imageNamed:MITImageBarButtonList];
    UIBarButtonItem *dismissMapButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_dismissFullScreenMap:)];
    self.toolbarItems = @[[UIBarButtonItem flexibleSpace],dismissMapButton];

    [self.contentContainerView bringSubviewToFront:self.mapViewContainer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.currentState == MITMartyRootViewControllerStateSearch) {
        UIEdgeInsets contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0);
        self.typeAheadViewController.tableView.contentInset = contentInset;
    }
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    if ([self isMapFullScreen]) {
        self.mapHeightConstraint.constant = CGRectGetHeight(self.contentContainerView.bounds);

        if ([self.mapHeightConstraint respondsToSelector:@selector(setActive:)]) {
            self.mapHeightConstraint.active = YES;
            self.defaultMapHeightConstraint.active = NO;
        } else {
            self.mapHeightConstraint.priority = UILayoutPriorityDefaultHigh;
            self.defaultMapHeightConstraint.priority = UILayoutPriorityDefaultLow;
        }
    } else {
        self.mapHeightConstraint.constant = 0;
        
        if (_mapVerticalOffset < 0) {
            self.defaultMapHeightConstraint.constant = _mapVerticalOffset * self.defaultMapHeightConstraint.multiplier;
        } else {
            self.defaultMapHeightConstraint.constant = 0;
        }

        if ([self.mapHeightConstraint respondsToSelector:@selector(setActive:)]) {
            self.mapHeightConstraint.active = NO;
            self.defaultMapHeightConstraint.active = YES;
        } else {
            self.mapHeightConstraint.priority = UILayoutPriorityDefaultLow;
            self.defaultMapHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self _transitionToState:self.currentState animated:animated completion:nil];
    
    [self setupNavigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadDataSourceForSearch:(NSString*)queryString completion:(void(^)(void))block
{
    if ([queryString length]) {
        [self.dataSource resourcesWithQuery:queryString completion:^(MITMartyResourceDataSource *dataSource, NSError *error) {
            if (error) {
                DDLogWarn(@"Error: %@",error);
                
                if (block) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:block];
                }
            } else {
                [self.managedObjectContext performBlockAndWait:^{
                    [self.managedObjectContext reset];

                    if (block) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
                    }
                }];
            }
        }];
    } else {
        self.contentContainerView.hidden = YES;
        self.helpTextView.hidden = NO;
    }
}

- (MITMartyResourceDataSource*)dataSource
{
    if (!_dataSource) {
        MITMartyResourceDataSource *dataSource = [[MITMartyResourceDataSource alloc] init];
        _dataSource = dataSource;
    }

    return _dataSource;
}

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

    [self.navigationItem setLeftBarButtonItem:[MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem];
}

#pragma mark Public Properties
- (void)setMapFullScreen:(BOOL)mapFullScreen
{
    [self setMapFullScreen:mapFullScreen animated:NO];
}

- (void)setMapFullScreen:(BOOL)mapFullScreen animated:(BOOL)animated
{
    if (_mapFullScreen != mapFullScreen) {
        _mapFullScreen = mapFullScreen;

        NSTimeInterval duration = (animated ? MITMartyRootPhoneDefaultAnimationDuration : 0);
        if (_mapFullScreen) {
            [UIView animateWithDuration:duration
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 CGFloat tableContainerTranslation = CGRectGetMaxY(self.contentContainerView.bounds) - CGRectGetMinY(self.tableViewContainer.frame);
                                 self.tableViewContainer.transform = CGAffineTransformMakeTranslation(0, tableContainerTranslation);
                                 self.mapViewContainer.transform = CGAffineTransformIdentity;
                                 
                                 [self.view setNeedsUpdateConstraints];
                                 [self.view layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.fullScreenMapGesture.enabled = NO;
                                 self.mapViewContainer.userInteractionEnabled = YES;
                                 [self.navigationController setToolbarHidden:NO animated:animated];
                             }];
        } else {
            [UIView animateWithDuration:duration
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.tableViewContainer.transform = CGAffineTransformIdentity;
                                 self.mapViewContainer.transform = _previousMapTransform;
                                 
                                 [self.view setNeedsUpdateConstraints];
                                 [self.view layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.fullScreenMapGesture.enabled = YES;
                                 self.mapViewContainer.userInteractionEnabled = NO;
                                 
                                 [self.mapViewController recenterOnVisibleResources:animated];
                                 [self.navigationController setToolbarHidden:YES animated:animated];
                                 [self.mapViewController showCalloutForResource:nil];
                             }];
        }
    }
}

#pragma mark resourcesTableViewController
- (void)loadResourcesTableViewController
{
    MITMartyResourcesTableViewController *resourcesTableViewController = [[MITMartyResourcesTableViewController alloc] init];
    resourcesTableViewController.delegate = self;
    [self _addChildViewController:resourcesTableViewController toView:self.tableViewContainer];
    _resourcesTableViewController = resourcesTableViewController;
}

- (MITMartyResourcesTableViewController*)resourcesTableViewController
{
    if (!_resourcesTableViewController) {
        [self loadResourcesTableViewController];
    }
    
    return _resourcesTableViewController;
}


#pragma mark mapViewController
- (MITMartyMapViewController*)mapViewController
{
    if (!_mapViewController) {
        [self loadMapViewController];
    }

    return _mapViewController;
}

- (void)loadMapViewController
{
    MITMartyMapViewController *mapViewController = [[MITMartyMapViewController alloc] init];

    [self _addChildViewController:mapViewController toView:self.mapViewContainer];
    _mapViewController = mapViewController;
}


#pragma mark typeAheadViewController
- (UITableViewController*)typeAheadViewController
{
    if (!_typeAheadViewController) {
        [self loadTypeAheadViewController];
    }

    return _typeAheadViewController;
}

- (void)loadTypeAheadViewController
{
    MITMartyRecentSearchController *typeAheadViewController = [[MITMartyRecentSearchController alloc] init];
    typeAheadViewController.delegate = self;
    [self _addChildViewController:typeAheadViewController toView:self.view];
    _typeAheadViewController = typeAheadViewController;
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
#pragma mark State Management
- (BOOL)_canTransitionToState:(MITMartyRootViewControllerState)newState
{
    if (self.currentState == newState) {
        return YES;
    }
    
    switch (self.currentState) {
        case MITMartyRootViewControllerStateInitial: {
            return (newState == MITMartyRootViewControllerStateSearch);
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            return ((newState == MITMartyRootViewControllerStateInitial) ||
                    (newState == MITMartyRootViewControllerStateNoResults) ||
                    (newState == MITMartyRootViewControllerStateResults));
        } break;
            
        case MITMartyRootViewControllerStateNoResults: {
            return (newState == MITMartyRootViewControllerStateSearch);
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            return (newState == MITMartyRootViewControllerStateSearch);
        } break;
    }
}

- (void)_transitionToState:(MITMartyRootViewControllerState)newState animated:(BOOL)animate completion:(void(^)(void))block
{
    NSAssert([self _canTransitionToState:newState], @"illegal state transition");
    if (self.currentState == newState) {
        return;
    }
    
    MITMartyRootViewControllerState oldState = self.currentState;
    
    [self _willTransitionToState:newState fromState:oldState];
    self.currentState = newState;
    
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
    
    NSTimeInterval animationDuration = (animate ? MITMartyRootPhoneDefaultAnimationDuration : 0);
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:0
                     animations:^{
                         [self _animateTransitionToState:newState fromState:oldState animated:animate];
                     } completion:^(BOOL finished) {
                         [self _didTransitionToState:newState fromState:oldState];
                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                             if (block) {
                                 block();
                             }
                         }];
                     }];
}

- (void)_willTransitionToState:(MITMartyRootViewControllerState)newState fromState:(MITMartyRootViewControllerState)oldState
{
    switch (newState) {
        case MITMartyRootViewControllerStateNoResults:
        case MITMartyRootViewControllerStateInitial: {
            self.helpTextView.hidden = NO;
            self.helpTextView.alpha = 0.;
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            self.typeAheadViewController.view.hidden = NO;
            self.typeAheadViewController.view.alpha = 0.;
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            self.contentContainerView.hidden = NO;
            self.contentContainerView.alpha = 0;
            [self.contentContainerView bringSubviewToFront:self.mapViewContainer];
        } break;
    }
    
    switch (oldState) {
        case MITMartyRootViewControllerStateNoResults:
        case MITMartyRootViewControllerStateInitial: {
            self.helpTextView.hidden = NO;
            self.helpTextView.alpha = 1;
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            self.typeAheadViewController.view.hidden = NO;
            self.typeAheadViewController.view.alpha = 1.;
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            self.contentContainerView.hidden = NO;
            self.contentContainerView.alpha = 1;
            [self.contentContainerView bringSubviewToFront:self.mapViewContainer];
        } break;
    }
}

- (void)_animateTransitionToState:(MITMartyRootViewControllerState)newState fromState:(MITMartyRootViewControllerState)oldState animated:(BOOL)animated
{
    switch (newState) {
        case MITMartyRootViewControllerStateNoResults:
        case MITMartyRootViewControllerStateInitial: {
            self.helpTextView.alpha = 1;
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            self.typeAheadViewController.view.alpha = 1;
            [self.navigationItem setLeftBarButtonItem:nil animated:animated];
            [self.searchBar setShowsCancelButton:YES animated:animated];
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            self.contentContainerView.alpha = 1;
            
            if (self.isMapFullScreen) {
                [self.navigationController setToolbarHidden:NO animated:animated];
            } else {
                [self.mapViewController.mapView selectAnnotation:nil animated:animated];
            }
        } break;
    }
    
    switch (oldState) {
        case MITMartyRootViewControllerStateNoResults:
        case MITMartyRootViewControllerStateInitial: {
            self.helpTextView.alpha = 0;
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            self.typeAheadViewController.view.alpha = 0;
            [self.searchBar setShowsCancelButton:NO animated:animated];
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            self.contentContainerView.alpha = 0;
            [self.navigationController setToolbarHidden:YES animated:animated];
        } break;
    }
}

- (void)_didTransitionToState:(MITMartyRootViewControllerState)newState fromState:(MITMartyRootViewControllerState)oldState
{
    switch (oldState) {
        case MITMartyRootViewControllerStateNoResults:
        case MITMartyRootViewControllerStateInitial: {
            self.helpTextView.hidden = YES;
        } break;
            
        case MITMartyRootViewControllerStateSearch: {
            [self.navigationItem setLeftBarButtonItem:[MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem animated:YES];
            self.typeAheadViewController.view.hidden = YES;
        } break;
            
        case MITMartyRootViewControllerStateResults: {
            self.contentContainerView.hidden = YES;
        } break;
    }
}

- (void)_searchSuggestionsTimerFired:(NSTimer*)timer
{
    [self.typeAheadViewController filterResultsUsingString:self.searchBar.text];
}

- (IBAction)_dismissFullScreenMap:(UIBarButtonItem*)sender
{
    if (self.currentState != MITMartyRootViewControllerStateResults) {
        return;
    }
    
    [self setMapFullScreen:NO animated:YES];
}

- (IBAction)_handleFullScreenMapGesture:(UITapGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer == self.fullScreenMapGesture) {
        if (self.currentState != MITMartyRootViewControllerStateResults) {
            return;
        }
        
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            CGPoint location = [gestureRecognizer locationInView:self.contentContainerView];

            if (CGRectContainsPoint(self.mapViewContainer.frame, location)) {
                [self setMapFullScreen:YES animated:YES];
            }
        }
    }
}

- (void)_addChildViewController:(UIViewController*)viewController toView:(UIView*)superview
{
    NSParameterAssert(viewController);
    NSParameterAssert(superview);
    
    
    [self addChildViewController:viewController];
    [viewController beginAppearanceTransition:YES animated:NO];
    
    viewController.view.frame = superview.bounds;
    viewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    viewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    [superview addSubview:viewController.view];
    
    [viewController endAppearanceTransition];
    [viewController didMoveToParentViewController:self];
}

- (void)_removeChildViewController:(UIViewController*)viewController
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
        searchBar.placeholder = @"Search Marty";
        searchBar.delegate = self;

        _searchBar = searchBar;
    }

    return searchBar;
}

#pragma mark - Delegation
#pragma mark MITMartyRecentSearchControllerDelegate
- (void)placeSelectionViewController:(UIViewController<MITMapPlaceSelector>*)viewController didSelectQuery:(NSString*)query
{
    self.searchBar.text = query;
    [self.searchBar resignFirstResponder];
}

#pragma mark MITMartyResourcesTableViewControllerDelegate
- (void)resourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController didSelectResource:(MITMartyResource *)resource
{
    MITMartyDetailTableViewController *detailViewController = [[MITMartyDetailTableViewController alloc] init];
    detailViewController.resource = resource;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (BOOL)shouldDisplayPlaceholderCellForResourcesTableViewController:(MITMartyResourcesTableViewController*)tableViewController
{
    return YES;
}

- (void)resourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController didScrollToContentOffset:(CGPoint)contentOffset
{
    if (contentOffset.y > 0) {
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -contentOffset.y);
        self.mapViewContainer.transform = transform;
        
        _previousMapTransform = transform;
        _mapVerticalOffset = 0;
    } else {
        _mapVerticalOffset = contentOffset.y;
        _previousMapTransform = CGAffineTransformIdentity;
        self.mapViewContainer.transform = CGAffineTransformIdentity;
    }
    
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (CGFloat)heightOfPlaceholderCellForResourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController
{
    return CGRectGetHeight(self.mapViewContainer.bounds);
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searching = YES;
    [self _transitionToState:MITMartyRootViewControllerStateSearch animated:YES completion:nil];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searching = NO;
    
    if ([self.searchBar.text length]) {
        NSString *queryString = [[searchBar.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([queryString caseInsensitiveCompare:self.dataSource.queryString] != NSOrderedSame) {
            
            [self.typeAheadViewController addRecentSearchItem:queryString];
            
            [self reloadDataSourceForSearch:queryString completion:^{
                MITMartyRootViewControllerState newState = MITMartyRootViewControllerStateNoResults;
                
                if ([self.dataSource.resources count]) {
                    newState = MITMartyRootViewControllerStateResults;
                    self.mapFullScreen = NO;
                }
                
                [self _transitionToState:newState animated:YES completion:^{
                    self.resourcesTableViewController.resources = self.dataSource.resources;
                    [self.mapViewController setResources:self.dataSource.resources animated:YES];
                }];
            }];
        } else {
            MITMartyRootViewControllerState newState = MITMartyRootViewControllerStateNoResults;
            if ([self.dataSource.resources count]) {
                newState = MITMartyRootViewControllerStateResults;
            }
            
            [self _transitionToState:newState animated:YES completion:nil];
        }
    } else {
        [self _transitionToState:MITMartyRootViewControllerStateNoResults animated:YES completion:nil];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];

    [self reloadDataSourceForSearch:searchBar.text completion:^{
        self.resourcesTableViewController.resources = self.dataSource.resources;
        self.mapViewController.resources = self.dataSource.resources;
    }];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchSuggestionsTimer invalidate];
    self.searchSuggestionsTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                   target:self
                                                                 selector:@selector(_searchSuggestionsTimerFired:)
                                                                 userInfo:nil
                                                                  repeats:NO];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
