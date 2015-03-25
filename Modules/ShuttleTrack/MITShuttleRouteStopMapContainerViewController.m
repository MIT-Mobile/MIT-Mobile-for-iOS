#import "MITShuttleRouteStopMapContainerViewController.h"
#import "MITShuttleMapViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITExtendedNavBarView.h"
#import "MITExtendedNavBarView.h"
#import "UINavigationBar+ExtensionPrep.h"
#import "UIKit+MITAdditions.h"
#import "MITShuttleStopsPageViewControllerDataSource.h"
#import "MITShuttleStopViewController.h"

typedef NS_ENUM(NSUInteger, MITShuttleRouteStopMapContainerState) {
    MITShuttleRouteStopMapContainerStateRoute = 0,
    MITShuttleRouteStopMapContainerStateStop,
    MITShuttleRouteStopMapContainerStateMap
};

typedef NS_ENUM(NSUInteger, MITShuttleStopSubtitleLabelAnimationType) {
    MITShuttleStopSubtitleLabelAnimationTypeNone = 0,
    MITShuttleStopSubtitleLabelAnimationTypeForward,
    MITShuttleStopSubtitleLabelAnimationTypeBackward
};

static const NSTimeInterval kStateTransitionDurationPortrait = 0.5;
static const NSTimeInterval kStateTransitionDurationLandscape = 0.3;

static const CGFloat kMapContainerViewEmbeddedHeightPortrait = 190.0;
static const CGFloat kMapContainerViewEmbeddedWidthLandscape = 320.0;

static const CGFloat kStopSubtitleAnimationSpan = 40.0;
static const NSTimeInterval kStopSubtitleAnimationDuration = 0.3;

static const CGFloat kNavigationBarStopStateExtensionHeight = 14.0;

@interface MITShuttleRouteStopMapContainerViewController () <MITShuttleRouteViewControllerDelegate, MITShuttleMapViewControllerDelegate, UIPageViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *mapContainerView;
@property (nonatomic, strong) UIView *routeStopContainerView;
@property (nonatomic, strong) MITShuttleMapViewController *mapViewController;
@property (nonatomic, strong) MITShuttleRouteViewController *routeViewController;
@property (nonatomic, strong) UIPageViewController *stopsPageViewController;
@property (nonatomic, strong) MITShuttleStopsPageViewControllerDataSource *stopsPagingDataSource;

@property (nonatomic, strong) UIView *stopTitleView;
@property (nonatomic, strong) UILabel *stopTitleLabel;
@property (nonatomic, strong) UILabel *stopSubtitleLabel;
@property (nonatomic, strong) MITExtendedNavBarView *navigationBarExtensionView;

@property (nonatomic, strong) NSArray *portraitConstraints;
@property (nonatomic, strong) NSArray *landscapeConstraints;

@property (nonatomic, strong) NSLayoutConstraint *routeStopContainerViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *routeStopContainerViewWidthConstraint;

@property (nonatomic, strong) NSLayoutConstraint *mapContainerViewPortraitHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *mapContainerViewLandscapeWidthConstraint;

@property (nonatomic, strong) NSLayoutConstraint *navigationBarExtensionViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *navigationBarExtensionViewTopSpaceConstraint;
@property (nonatomic, strong) NSLayoutConstraint *stopSubtitleLabelCenterAlignmentConstraint;

@property (nonatomic, assign) MITShuttleRouteStopMapContainerState state;

@property (nonatomic, assign) BOOL isRotating;

@end

@implementation MITShuttleRouteStopMapContainerViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    self = [self initWithNibName:nil bundle:nil];
    
    if (self) {
        _route = route;
        _stop = stop;
        _state = stop ? MITShuttleRouteStopMapContainerStateStop : MITShuttleRouteStopMapContainerStateRoute;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupViews];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [self addPortraitConstraints];
    } else {
        [self addLandscapeConstraints];
    }
    
    [self setupChildViewControllers];
    
    if (!self.isRotating) {
        [self configureLayoutForState:self.state animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareNavBarForAppearance];
}

- (void)prepareNavBarForAppearance
{
    [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:[UIColor mit_navBarColor]];
    self.navigationBarExtensionView.backgroundColor = [UIColor mit_navBarColor];
    self.navigationBarExtensionViewHeightConstraint.constant = kNavigationBarStopStateExtensionHeight;
}

#pragma mark - View Setup

- (void)setupViews
{
    [self setupNavigationBarExtensionViews];
    [self setupStopTitleViews];
    [self setupScrollView];
    [self setupMapContainerView];
    [self setupRouteStopContainerView];
}

- (void)setupNavigationBarExtensionViews
{
    self.navigationBarExtensionView = [[MITExtendedNavBarView alloc] init];
    self.navigationBarExtensionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.navigationBarExtensionView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[navigationBarExtensionView]-0-|" options:0 metrics:nil views:@{@"navigationBarExtensionView": self.navigationBarExtensionView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[navigationBarExtensionView]" options:0 metrics:nil views:@{@"navigationBarExtensionView": self.navigationBarExtensionView}]];
    
    self.navigationBarExtensionViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBarExtensionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kNavigationBarStopStateExtensionHeight];
    [self.navigationBarExtensionView addConstraint:self.navigationBarExtensionViewHeightConstraint];
    
    self.navigationBarExtensionViewTopSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBarExtensionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.navigationBarExtensionViewTopSpaceConstraint];
}

- (void)setupStopTitleViews
{
    self.stopTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 195, 60)];
    
    // Stop title label
    self.stopTitleLabel = [[UILabel alloc] init];
    self.stopTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.stopTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.stopTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stopTitleView addSubview:self.stopTitleLabel];
    
    [self.stopTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-2-[stopTitleLabel]-2-|" options:0 metrics:nil views:@{@"stopTitleLabel": self.stopTitleLabel}]];
    [self.stopTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[stopTitleLabel(==21)]" options:0 metrics:nil views:@{@"stopTitleLabel": self.stopTitleLabel}]];
    
    // Stop subtitle label
    self.stopSubtitleLabel = [[UILabel alloc] init];
    self.stopSubtitleLabel.font = [UIFont systemFontOfSize:15];
    self.stopSubtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.stopSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stopTitleView addSubview:self.stopSubtitleLabel];
    
    [self.stopTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[stopSubtitleLabel(==18)]-3-|" options:0 metrics:nil views:@{@"stopSubtitleLabel": self.stopSubtitleLabel}]];
    [self.stopTitleView addConstraint:[NSLayoutConstraint constraintWithItem:self.stopSubtitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.stopTitleView attribute:NSLayoutAttributeWidth multiplier:1 constant:-4]];
    
    self.stopSubtitleLabelCenterAlignmentConstraint = [NSLayoutConstraint constraintWithItem:self.stopSubtitleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.stopTitleView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [self.stopTitleView addConstraint:self.stopSubtitleLabelCenterAlignmentConstraint];
}

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView": self.scrollView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[navigationBarExtensionView]-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView": self.scrollView, @"navigationBarExtensionView": self.navigationBarExtensionView}]];
}

- (void)setupMapContainerView
{
    self.mapContainerView = [[UIView alloc] init];
    UITapGestureRecognizer *mapTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapContainerViewTapped)];
    [self.mapContainerView addGestureRecognizer:mapTapGestureRecognizer];
    self.mapContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.mapContainerView];
}

- (void)setupRouteStopContainerView
{
    self.routeStopContainerView = [[UIView alloc] init];
    self.routeStopContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.routeStopContainerView];
}

#pragma mark - Child ViewController Setup

- (void)setupChildViewControllers
{
    [self setupMapViewController];
    [self setupRouteViewController];
    [self setupStopsPageViewController];
}

- (void)setupMapViewController
{
    self.mapViewController = [[MITShuttleMapViewController alloc] initWithRoute:self.route];
    self.mapViewController.delegate = self;
    self.mapViewController.stop = self.stop;
    [self.mapViewController setState:MITShuttleMapStateContracted];
    
    self.mapViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.mapViewController];
    [self.mapContainerView addSubview:self.mapViewController.view];
    [self.mapViewController didMoveToParentViewController:self];
    
    [self.mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mapView]-0-|" options:0 metrics:nil views:@{@"mapView": self.mapViewController.view}]];
    [self.mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|" options:0 metrics:nil views:@{@"mapView": self.mapViewController.view}]];
}

- (void)setupRouteViewController
{
    self.routeViewController = [[MITShuttleRouteViewController alloc] initWithRoute:self.route];
    self.routeViewController.delegate = self;
    
    self.routeViewController.tableView.scrollsToTop = NO;
    self.routeViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.routeViewController];
    [self.routeStopContainerView addSubview:self.routeViewController.view];
    [self.routeViewController didMoveToParentViewController:self];
    
    [self.routeStopContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[routeView]-0-|" options:0 metrics:nil views:@{@"routeView": self.routeViewController.view}]];
    [self.routeStopContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[routeView]-0-|" options:0 metrics:nil views:@{@"routeView": self.routeViewController.view}]];
}

- (void)setupStopsPageViewController
{
    self.stopsPagingDataSource = [[MITShuttleStopsPageViewControllerDataSource alloc] init];
    self.stopsPagingDataSource.stops = [self.route.stops array];
    
    self.stopsPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.stopsPageViewController.dataSource = self.stopsPagingDataSource;
    self.stopsPageViewController.delegate = self;
    
    self.stopsPageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.stopsPageViewController];
    [self.routeStopContainerView addSubview:self.stopsPageViewController.view];
    [self.stopsPageViewController didMoveToParentViewController:self];
    
    [self.routeStopContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[stopsPageViewController]-0-|" options:0 metrics:nil views:@{@"stopsPageViewController": self.stopsPageViewController.view}]];
    [self.routeStopContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[stopsPageViewController]-0-|" options:0 metrics:nil views:@{@"stopsPageViewController": self.stopsPageViewController.view}]];
}

#pragma mark - Constraints

- (void)addPortraitConstraints
{
    if (!self.portraitConstraints) {
        NSMutableArray *portraitConstraints = [NSMutableArray array];
        
        // Map container constraints
        [portraitConstraints addObject:[NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        [portraitConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mapContainerView]-0-|" options:0 metrics:nil views:@{@"mapContainerView": self.mapContainerView}]];
        [portraitConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapContainerView]" options:0 metrics:nil views:@{@"mapContainerView": self.mapContainerView}]];
        self.mapContainerViewPortraitHeightConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedHeightPortrait];
        
        // Route/Stop container constraints
        [portraitConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[routeStopContainerView]-0-|" options:0 metrics:nil views:@{@"routeStopContainerView": self.routeStopContainerView}]];
        [portraitConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mapContainerView]-0-[routeStopContainerView]-0-|" options:0 metrics:nil views:@{@"routeStopContainerView": self.routeStopContainerView, @"mapContainerView": self.mapContainerView}]];
        self.routeStopContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        
        self.portraitConstraints = [NSArray arrayWithArray:portraitConstraints];
    }
    
    [self.scrollView addConstraints:self.portraitConstraints];
    [self.scrollView addConstraint:self.routeStopContainerViewHeightConstraint];
    [self.scrollView addConstraint:self.mapContainerViewPortraitHeightConstraint];
}

- (void)addLandscapeConstraints
{
    if (!self.landscapeConstraints) {
        NSMutableArray *landscapeConstraints = [NSMutableArray array];
        
        // Map container constraints
        [landscapeConstraints addObject:[NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
        [landscapeConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mapContainerView]" options:0 metrics:nil views:@{@"mapContainerView": self.mapContainerView}]];
        [landscapeConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapContainerView]-0-|" options:0 metrics:nil views:@{@"mapContainerView": self.mapContainerView}]];
        self.mapContainerViewLandscapeWidthConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedWidthLandscape];
        
        // Route/Stop container constraints
        [landscapeConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[mapContainerView]-0-[routeStopContainerView]-0-|" options:0 metrics:nil views:@{@"routeStopContainerView": self.routeStopContainerView, @"mapContainerView": self.mapContainerView}]];
        [landscapeConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[routeStopContainerView]-0-|" options:0 metrics:nil views:@{@"routeStopContainerView": self.routeStopContainerView}]];
        self.routeStopContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-kMapContainerViewEmbeddedWidthLandscape];
        
        self.landscapeConstraints = [NSArray arrayWithArray:landscapeConstraints];
    }
    
    [self.scrollView addConstraints:self.landscapeConstraints];
    [self.scrollView addConstraint:self.routeStopContainerViewWidthConstraint];
    [self.scrollView addConstraint:self.mapContainerViewLandscapeWidthConstraint];
}

- (void)removePortraitConstraints
{
    [self.scrollView removeConstraints:self.portraitConstraints];
    [self.scrollView removeConstraint:self.routeStopContainerViewHeightConstraint];
    [self.scrollView removeConstraint:self.mapContainerViewPortraitHeightConstraint];
}

- (void)removeLandscapeConstraints
{
    [self.scrollView removeConstraints:self.landscapeConstraints];
    [self.scrollView removeConstraint:self.routeStopContainerViewWidthConstraint];
    [self.scrollView removeConstraint:self.mapContainerViewLandscapeWidthConstraint];
}

#pragma mark - Custom Getters/Setters

- (void)setStop:(MITShuttleStop *)stop
{
    _stop = stop;
    self.mapViewController.stop = stop;
    
    if (self.state == MITShuttleRouteStopMapContainerStateStop) {
        [self.mapViewController centerToShuttleStop:stop animated:YES];
    }
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return;
    }
    
    self.isRotating = YES;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self removeLandscapeConstraints];
    } else {
        [self removePortraitConstraints];
    }
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self addLandscapeConstraints];
    } else {
        [self addPortraitConstraints];
    }
    
    [self.view setNeedsUpdateConstraints];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.isRotating = NO;
    
    [self configureLayoutForState:self.state animated:NO];
}

#pragma mark - MITShuttleMapViewControllerDelegate Methods

- (void)shuttleMapViewControllerExitFullscreenButtonPressed:(MITShuttleMapViewController *)mapViewController
{
    if (self.state == MITShuttleRouteStopMapContainerStateMap) {
        self.mapViewController.stop = nil;
        // Always return to route state listing the stops regardless of previous state.
        [self setState:MITShuttleRouteStopMapContainerStateRoute animated:YES];
    }
}

- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didClickCalloutForStop:(MITShuttleStop *)stop
{
    self.stop = stop;
    [self setState:MITShuttleRouteStopMapContainerStateStop animated:YES];
}

#pragma mark - MITShuttleRouteViewControllerDelegate

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didSelectStop:(MITShuttleStop *)stop
{
    self.stop = stop;
    [self setState:MITShuttleRouteStopMapContainerStateStop animated:YES];
}

#pragma mark - Map Tap Gesture Recognizer

- (void)mapContainerViewTapped
{
    if (self.state != MITShuttleRouteStopMapContainerStateMap) {
        [self setState:MITShuttleRouteStopMapContainerStateMap animated:YES];
    }
}

#pragma mark - State Configuration

- (void)setState:(MITShuttleRouteStopMapContainerState)state
{
    [self setState:state animated:NO];
}

- (void)setState:(MITShuttleRouteStopMapContainerState)state animated:(BOOL)animated
{
    [self configureLayoutForState:state animated:animated];
    _state = state;
}

- (void)configureLayoutForState:(MITShuttleRouteStopMapContainerState)state animated:(BOOL)animated
{
    switch (state) {
        case MITShuttleRouteStopMapContainerStateRoute:
            [self configureLayoutForRouteStateAnimated:animated];
            break;
        case MITShuttleRouteStopMapContainerStateStop:
            [self configureLayoutForStopStateAnimated:animated];
            break;
        case MITShuttleRouteStopMapContainerStateMap:
            [self configureLayoutForMapStateAnimated:animated];
            break;
        default:
            break;
    }
    
    // Always bring this to the front, since even though we set up our constraints properly, if another view is 0px below this and has a higher z-index, the extension view's layer shadow will be covered
    [self.view bringSubviewToFront:self.navigationBarExtensionView];
}

- (void)configureLayoutForRouteStateAnimated:(BOOL)animated
{
    [self setTitleForRoute:self.route];
    [self setRouteViewHidden:NO];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [self.scrollView removeConstraint:self.mapContainerViewPortraitHeightConstraint];
        self.mapContainerViewPortraitHeightConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedHeightPortrait];
        [self.scrollView addConstraint:self.mapContainerViewPortraitHeightConstraint];
        
        [self.scrollView removeConstraint:self.routeStopContainerViewHeightConstraint];
        self.routeStopContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.routeViewController.targetTableViewHeight];
        [self.scrollView addConstraint:self.routeStopContainerViewHeightConstraint];
    } else {
        [self.scrollView removeConstraint:self.mapContainerViewLandscapeWidthConstraint];
        self.mapContainerViewLandscapeWidthConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedWidthLandscape];
        [self.scrollView addConstraint:self.mapContainerViewLandscapeWidthConstraint];
        
        [self.scrollView removeConstraint:self.routeStopContainerViewWidthConstraint];
        self.routeStopContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-kMapContainerViewEmbeddedWidthLandscape];
        [self.scrollView addConstraint:self.routeStopContainerViewWidthConstraint];
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        [self.mapViewController setMapToolBarHidden:YES];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setStopViewHidden:YES];
        [self.mapViewController setState:MITShuttleMapStateContracted];
        self.routeViewController.shouldSuppressPredictionRefreshReloads = NO;
        [self.routeViewController.tableView reloadData];
    };
    
    self.routeViewController.tableView.contentOffset = CGPointZero;
    [self.mapViewController setState:MITShuttleMapStateContracting];
    
    if (animated) {
        [UIView animateWithDuration:[self stateTransitionDuration]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }
    
    self.stop = nil;
    [self.mapViewController setRoute:self.route stop:nil];
    
    self.mapViewController.shouldUsePinAnnotations = NO;
    [self.mapViewController refreshStopAnnotationImagesAnimated:NO];
}

- (void)configureLayoutForStopStateAnimated:(BOOL)animated
{
    [self setTitleForRoute:self.route stop:self.stop animated:animated];
    [self setStopViewHidden:NO];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [self.scrollView removeConstraint:self.mapContainerViewPortraitHeightConstraint];
        self.mapContainerViewPortraitHeightConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedHeightPortrait];
        [self.scrollView addConstraint:self.mapContainerViewPortraitHeightConstraint];
        
        [self.scrollView removeConstraint:self.routeStopContainerViewHeightConstraint];
        self.routeStopContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeHeight multiplier:1 constant:-kMapContainerViewEmbeddedHeightPortrait];
        [self.scrollView addConstraint:self.routeStopContainerViewHeightConstraint];
    } else {
        [self.scrollView removeConstraint:self.mapContainerViewLandscapeWidthConstraint];
        self.mapContainerViewLandscapeWidthConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kMapContainerViewEmbeddedWidthLandscape];
        [self.scrollView addConstraint:self.mapContainerViewLandscapeWidthConstraint];
        
        [self.scrollView removeConstraint:self.routeStopContainerViewWidthConstraint];
        self.routeStopContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-kMapContainerViewEmbeddedWidthLandscape];
        [self.scrollView addConstraint:self.routeStopContainerViewWidthConstraint];
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:YES];
        [self.mapViewController setMapToolBarHidden:YES];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self.stopsPageViewController setViewControllers:@[[self.stopsPagingDataSource viewControllerForStop:self.stop]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        [self setRouteViewHidden:YES];
        [self.mapViewController setState:MITShuttleMapStateContracted];
    };
    
    [self.mapViewController setState:MITShuttleMapStateContracting];
    
    if (animated) {
        [UIView animateWithDuration:[self stateTransitionDuration]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }
    
    [self.mapViewController centerToShuttleStop:self.stop animated:animated];
    
    self.mapViewController.shouldUsePinAnnotations = NO;
    [self.mapViewController refreshStopAnnotationImagesAnimated:NO];
}

- (void)configureLayoutForMapStateAnimated:(BOOL)animated
{
    self.routeViewController.shouldSuppressPredictionRefreshReloads = YES;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [self.scrollView removeConstraint:self.routeStopContainerViewHeightConstraint];
        self.routeStopContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        [self.scrollView addConstraint:self.routeStopContainerViewHeightConstraint];
        
        [self.scrollView removeConstraint:self.mapContainerViewPortraitHeightConstraint];
        self.mapContainerViewPortraitHeightConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
        [self.scrollView addConstraint:self.mapContainerViewPortraitHeightConstraint];
    } else {
        [self.scrollView removeConstraint:self.mapContainerViewLandscapeWidthConstraint];
        self.mapContainerViewLandscapeWidthConstraint = [NSLayoutConstraint constraintWithItem:self.mapContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
        [self.scrollView addConstraint:self.mapContainerViewLandscapeWidthConstraint];
        
        [self.scrollView removeConstraint:self.routeStopContainerViewWidthConstraint];
        self.routeStopContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.routeStopContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        [self.scrollView addConstraint:self.routeStopContainerViewWidthConstraint];
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        [self.mapViewController setMapToolBarHidden:NO];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self.mapViewController setState:MITShuttleMapStateExpanded];
    };
    
    [self.mapViewController setState:MITShuttleMapStateExpanding];
    
    if (animated) {
        [UIView animateWithDuration:[self stateTransitionDuration]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }
    
    [self setTitleForRoute:self.route];
    
    self.mapViewController.shouldUsePinAnnotations = YES;
    [self.mapViewController refreshStopAnnotationImagesAnimated:NO];
}

- (NSTimeInterval)stateTransitionDuration
{
    return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? kStateTransitionDurationLandscape : kStateTransitionDurationPortrait;
}

#pragma mark - Showing/Hiding Route and Stop

- (void)setRouteViewHidden:(BOOL)hidden
{
    self.routeViewController.view.hidden = hidden;
}

- (void)setStopViewHidden:(BOOL)hidden
{
    self.stopsPageViewController.view.hidden = hidden;
}

#pragma mark - Navigation Bar Title

- (void)setTitleForRoute:(MITShuttleRoute *)route
{
    self.title = route.title;
    self.navigationItem.titleView = nil;
}

- (void)setTitleForRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop animated:(BOOL)animated
{
    self.navigationItem.titleView = self.stopTitleView;
    self.stopTitleLabel.text = route.title;
    [self setStopSubtitleWithStop:stop animationType:MITShuttleStopSubtitleLabelAnimationTypeNone];
    if (animated) {
        self.stopSubtitleLabel.alpha = 0;
        [UIView animateWithDuration:[self stateTransitionDuration] animations:^{
            self.stopSubtitleLabel.alpha = 1;
        }];
    }
}

- (void)setTitleForStop:(MITShuttleStop *)stop
{
    self.title = stop.title;
    self.navigationItem.titleView = nil;
}

- (void)setStopSubtitleWithStop:(MITShuttleStop *)stop animationType:(MITShuttleStopSubtitleLabelAnimationType)animationType
{
    if (animationType == MITShuttleStopSubtitleLabelAnimationTypeNone) {
        self.stopSubtitleLabel.text = stop.title;
    } else {
        CGPoint stopSubtitleLabelCenter = self.stopSubtitleLabel.center;
        CGPoint initialTempLabelCenter = CGPointZero;
        switch (animationType) {
            case MITShuttleStopSubtitleLabelAnimationTypeForward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(kStopSubtitleAnimationSpan, 0));
                self.stopSubtitleLabelCenterAlignmentConstraint.constant = -kStopSubtitleAnimationSpan;
                break;
            case MITShuttleStopSubtitleLabelAnimationTypeBackward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(-kStopSubtitleAnimationSpan, 0));
                self.stopSubtitleLabelCenterAlignmentConstraint.constant = kStopSubtitleAnimationSpan;
                break;
            default:
                break;
        }
        
        UILabel *tempLabel = [self tempStopSubtitleLabelWithStop:stop];
        tempLabel.center = initialTempLabelCenter;
        tempLabel.alpha = 0;
        [self.stopTitleView addSubview:tempLabel];
        
        [UIView animateWithDuration:kStopSubtitleAnimationDuration animations:^{
            tempLabel.center = stopSubtitleLabelCenter;
            tempLabel.alpha = 1;
            self.stopSubtitleLabel.alpha = 0;
            [self.stopTitleView layoutIfNeeded];
        } completion:^(BOOL finished) {
            [tempLabel removeFromSuperview];
            self.stopSubtitleLabel.text = stop.title;
            self.stopSubtitleLabelCenterAlignmentConstraint.constant = 0;
            self.stopSubtitleLabel.alpha = 1;
            [self.stopTitleView layoutIfNeeded];
        }];
    }
}

- (UILabel *)tempStopSubtitleLabelWithStop:(MITShuttleStop *)stop
{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:self.stopSubtitleLabel.frame];
    tempLabel.backgroundColor = [UIColor clearColor];
    tempLabel.textAlignment = NSTextAlignmentCenter;
    tempLabel.textColor = self.stopSubtitleLabel.textColor;
    tempLabel.font = self.stopSubtitleLabel.font;
    tempLabel.text = stop.title;
    [tempLabel sizeToFit];
    return tempLabel;
}

#pragma mark - Navigation Bar Extension

- (void)setNavigationBarExtended:(BOOL)extended
{
    dispatch_block_t frameAdjustmentBlock = ^{
        self.navigationBarExtensionViewTopSpaceConstraint.constant = extended ? 0 : -kNavigationBarStopStateExtensionHeight;
    };
    
    if (extended && self.isRotating) {
        // Wait until UINavigationBar frame adjustments are made as a result of the rotation
        // Otherwise, bottom shadow will appear in the middle of the extended bar during rotation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), frameAdjustmentBlock);
    } else {
        frameAdjustmentBlock();
    }
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    // There should only be one view controller displayed at a time
    MITShuttleStopViewController *stopVC = [pendingViewControllers firstObject];
    MITShuttleStop *stop = stopVC.stop;
    
    MITShuttleStopSubtitleLabelAnimationType animationType;
    NSInteger previousStopIndex = [self.route.stops indexOfObject:self.stop];
    NSInteger newStopIndex = [self.route.stops indexOfObject:stop];
    NSInteger maxIndex = self.route.stops.count - 1;
    if (previousStopIndex == maxIndex && newStopIndex == 0) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex == 0 && newStopIndex == maxIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else if (previousStopIndex < newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex > newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeNone;
    }
    [self setStopSubtitleWithStop:stop animationType:animationType];
    self.stop = stop;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    // There should only be one view controller displayed at a time
    MITShuttleStopViewController *stopVC = [pageViewController.viewControllers firstObject];
    MITShuttleStop *stop = stopVC.stop;
    
    MITShuttleStopSubtitleLabelAnimationType animationType;
    NSInteger previousStopIndex = [self.route.stops indexOfObject:self.stop];
    NSInteger newStopIndex = [self.route.stops indexOfObject:stop];
    NSInteger maxIndex = self.route.stops.count - 1;
    if (previousStopIndex == maxIndex && newStopIndex == 0) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex == 0 && newStopIndex == maxIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else if (previousStopIndex < newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex > newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeNone;
    }
    [self setStopSubtitleWithStop:stop animationType:animationType];
    self.stop = stop;
}

#pragma mark - UINavigationBarDelegate

- (BOOL)navigationShouldPopOnBackButton
{
    if (self.state == MITShuttleRouteStopMapContainerStateRoute) {
        return YES;
    } else {
        [self configureLayoutForState:MITShuttleRouteStopMapContainerStateRoute animated:YES];
        self.state = MITShuttleRouteStopMapContainerStateRoute;
        return NO;
    }
}

@end
