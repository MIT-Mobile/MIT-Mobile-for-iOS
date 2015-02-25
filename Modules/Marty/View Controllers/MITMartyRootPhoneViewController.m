#import "MITMartyRootPhoneViewController.h"
#import "MITMartyResourceDataSource.h"
#import "MITMartyModel.h"
#import "MITMartyResourcesTableViewController.h"
#import "MITMartyDetailTableViewController.h"
#import "MITSlidingViewController.h"
#import "MITMartyMapViewController.h"
#import "DDLog.h"
#import "MITAdditions.h"

@interface MITMartyRootPhoneViewController () <MITMartyResourcesTableViewControllerDelegate,UISearchDisplayDelegate,UITableViewDataSource,UISearchBarDelegate>

// These are currently strong since, if they are weak,
// they are being released during the various animations and
// wreaking havoc. Guessing it's either in the updateViewConstraints
// or the toggle animation.
// TODO: Figure out exactly where the 'weak' semantics go off the rails
// (bskinner 2015.02.25)
@property(nonatomic,strong) IBOutlet NSLayoutConstraint *mapHeightConstraint;
@property(nonatomic,strong) IBOutlet NSLayoutConstraint *defaultMapHeightConstraint;

@property(nonatomic,getter=isMapFullScreen) BOOL mapFullScreen;
@property(nonatomic,weak) UITapGestureRecognizer *fullScreenMapGesture;

@property(nonatomic,strong) MITMartyResourceDataSource *dataSource;

@property(nonatomic,readonly,weak) MITMartyResource *resource;
@property(nonatomic,readonly,weak) MITMartyResourcesTableViewController *resourcesTableViewController;
@property(nonatomic,readonly,weak) MITMartyMapViewController *mapViewController;

@property(nonatomic,weak) UIView *searchBarContainer;
@property(nonatomic,weak) UISearchBar *searchBar;
@property(nonatomic,getter=isSearching) BOOL searching;
@property(nonatomic,readonly,weak) UITableViewController *typeAheadViewController;

- (IBAction)didTapSearchItem:(UIBarButtonItem*)sender;
@end

@implementation MITMartyRootPhoneViewController {
    CGAffineTransform _previousMapTransform;
}

@synthesize resource = _resource;
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
    [self.contentContainerView addGestureRecognizer:gestureRecognizer];

    UIImage *image = [UIImage imageNamed:MITImageBarButtonList];
    UIBarButtonItem *dismissMapButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_dismissFullScreenMap:)];
    self.toolbarItems = @[[UIBarButtonItem flexibleSpace],dismissMapButton];

    [self.contentContainerView bringSubviewToFront:self.mapViewContainer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self resizeAndAlignSearchBar];
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
                self.contentContainerView.hidden = YES;
                self.helpTextView.hidden = NO;
            } else {
                self.contentContainerView.hidden = NO;
                self.helpTextView.hidden = YES;

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

        NSTimeInterval duration = (animated ? 0.5 : 0);
        if (_mapFullScreen) {
            _previousMapTransform = self.mapViewContainer.transform;

            [UIView animateWithDuration:duration
                                  delay:0
                                options:0
                             animations:^{
                                 CGFloat tableContainerTranslation = CGRectGetMaxY(self.contentContainerView.bounds) - CGRectGetMinY(self.tableViewContainer.frame);
                                 self.tableViewContainer.transform = CGAffineTransformMakeTranslation(0, tableContainerTranslation);
                                 [self.navigationController setToolbarHidden:NO animated:YES];

                                 [self.view setNeedsUpdateConstraints];
                                 [self.view layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.fullScreenMapGesture.enabled = NO;
                                 self.mapViewContainer.userInteractionEnabled = YES;
                             }];
        } else {
            [UIView animateWithDuration:duration
                                  delay:0
                                options:0
                             animations:^{
                                 [self.navigationController setToolbarHidden:YES animated:NO];
                                 self.tableViewContainer.transform = CGAffineTransformIdentity;
                                 self.mapViewContainer.transform = _previousMapTransform;

                                 [self.view setNeedsUpdateConstraints];
                                 [self.view layoutIfNeeded];
                                 [self.contentContainerView bringSubviewToFront:self.mapViewContainer];
                             } completion:^(BOOL finished) {
                                 self.fullScreenMapGesture.enabled = YES;
                                 self.mapViewContainer.userInteractionEnabled = NO;
                                 _previousMapTransform = CGAffineTransformIdentity;
                             }];
        }
    }
}

- (void)setSearching:(BOOL)searching
{
    [self setSearching:searching animated:NO];
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated
{
    if (_searching != searching) {
        [self willChangeSearching:searching animated:animated];
        BOOL oldValue = _searching;
        _searching = searching;
        [self didChangeSearching:oldValue animated:animated];
    }
}

- (void)willChangeSearching:(BOOL)newValue animated:(BOOL)animated
{

}

- (void)didChangeSearching:(BOOL)oldValue animated:(BOOL)animated
{
    [self.searchDisplayController setActive:self.isSearching animated:animated];
}

- (MITMartyResourcesTableViewController*)resourcesTableViewController
{
    if (!_resourcesTableViewController) {
        MITMartyResourcesTableViewController *resourcesTableViewController = [[MITMartyResourcesTableViewController alloc] init];
        resourcesTableViewController.delegate = self;
        
        [self addChildViewController:resourcesTableViewController];
        [resourcesTableViewController beginAppearanceTransition:YES animated:NO];
        resourcesTableViewController.view.frame = self.tableViewContainer.bounds;
        resourcesTableViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        resourcesTableViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        [self.tableViewContainer addSubview:resourcesTableViewController.view];
        [resourcesTableViewController endAppearanceTransition];
        [resourcesTableViewController didMoveToParentViewController:self];
        
        _resourcesTableViewController = resourcesTableViewController;
    }
    
    return _resourcesTableViewController;
}

- (MITMartyMapViewController*)mapViewController
{
    if (!_mapViewController) {
        MITMartyMapViewController *mapViewController = [[MITMartyMapViewController alloc] init];

        [self addChildViewController:mapViewController];
        [mapViewController beginAppearanceTransition:YES animated:NO];
        mapViewController.view.frame = self.mapViewContainer.bounds;
        mapViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        [self.mapViewContainer addSubview:mapViewController.view];
        [mapViewController endAppearanceTransition];
        [mapViewController didMoveToParentViewController:self];

        _mapViewController = mapViewController;
    }

    return _mapViewController;
}

- (UITableViewController*)typeAheadViewController
{
    if (!_typeAheadViewController) {
        UITableViewController *typeAheadViewController = [[UITableViewController alloc] init];

        [self addChildViewController:typeAheadViewController];
        [typeAheadViewController beginAppearanceTransition:YES animated:NO];

        typeAheadViewController.view.frame = self.view.bounds;
        typeAheadViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        typeAheadViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        [self.view addSubview:typeAheadViewController.view];
        [typeAheadViewController endAppearanceTransition];
        [typeAheadViewController didMoveToParentViewController:self];

        _typeAheadViewController = typeAheadViewController;
    }

    return _typeAheadViewController;
}

- (void)removeTypeAheadViewController
{
    [self.typeAheadViewController willMoveToParentViewController:nil];
    [self.typeAheadViewController beginAppearanceTransition:NO animated:NO];
    [self.typeAheadViewController.view removeFromSuperview];
    [self.typeAheadViewController endAppearanceTransition];
    [self.typeAheadViewController removeFromParentViewController];
    _typeAheadViewController = nil;
}

- (NSArray*)resources
{
    __block NSArray *resourceObjects = nil;
    [self.managedObjectContext performBlockAndWait:^{
        resourceObjects = [self.managedObjectContext transferManagedObjects:self.dataSource.resources];
    }];

    return resourceObjects;
}

#pragma mark Private
- (void)_dismissFullScreenMap:(UIBarButtonItem*)sender
{
    [self setMapFullScreen:NO animated:YES];
}

- (void)_handleFullScreenMapGesture:(UITapGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [gestureRecognizer locationInView:self.contentContainerView];

        if (CGRectContainsPoint(self.mapViewContainer.frame, location)) {
            [self setMapFullScreen:YES animated:YES];
        }
    }
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

- (IBAction)didTapSearchItem:(UIBarButtonItem*)sender
{
    [self.searchDisplayController setActive:YES animated:YES];
}

- (void)closeSearchBar
{
    [self.navigationItem setLeftBarButtonItem:[[MIT_MobileAppDelegate applicationDelegate] rootViewController].leftBarButtonItem animated:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark Delegation
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
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -contentOffset.y);
    self.mapViewContainer.transform = transform;
}

- (CGFloat)heightOfPlaceholderCellForResourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController
{
    return CGRectGetHeight(self.mapViewContainer.bounds);
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [self resizeAndAlignSearchBar];

    self.typeAheadViewController.view.frame = self.view.bounds;
    self.typeAheadViewController.view.hidden = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self closeSearchBar];
    self.typeAheadViewController.view.hidden = YES;

    [self reloadDataSourceForSearch:searchBar.text completion:^{
        self.resourcesTableViewController.resources = self.dataSource.resources;
        [self.mapViewController setResources:self.dataSource.resources animated:YES];
    }];
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
 /*   NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (searchText) {
        userInfo[kMITMapSearchSuggestionsTimerUserInfoKeySearchText] = searchText;
    }

    self.searchSuggestionsTimer = [NSTimer scheduledTimerWithTimeInterval:kMITMapSearchSuggestionsTimerWaitDuration
                                                                   target:self
                                                                 selector:@selector(searchSuggestionsTimerFired:)
                                                                 userInfo:userInfo
                                                                  repeats:NO];

    if (!searchBar.isFirstResponder) {
        //self.searchBarShouldBeginEditing = NO;
        //   [self clearPlacesAnimated:YES];
    }*/
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    //BOOL shouldBeginEditing = self.searchBarShouldBeginEditing;
    //self.searchBarShouldBeginEditing = YES;
    return YES;// shouldBeginEditing;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if ([searchBar.text length] == 0) {
        //[self clearPlacesAnimated:YES];
    }
}

- (void)resizeAndAlignSearchBar
{
    // Force size to width of view
    CGRect bounds = self.searchBarContainer.bounds;
    bounds.size.width = CGRectGetWidth(self.view.bounds);
    self.searchBarContainer.bounds = bounds;
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
