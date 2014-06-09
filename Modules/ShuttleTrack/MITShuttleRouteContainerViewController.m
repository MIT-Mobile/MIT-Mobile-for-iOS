#import "MITShuttleRouteContainerViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"

static const NSTimeInterval kStateTransitionDurationPortrait = 0.5;
static const NSTimeInterval kStateTransitionDurationLandscape = 0.3;

static const CGFloat kMapContainerViewEmbeddedHeightPortrait = 190.0;
static const CGFloat kMapContainerViewEmbeddedWidthRatioLandscape = 320.0 / 568.0;

static const CGFloat kStopSubtitleAnimationSpan = 40.0;
static const NSTimeInterval kStopSubtitleAnimationDuration = 0.3;

static const CGFloat kNavigationBarStopStateExtension = 14.0;

typedef enum {
    MITShuttleStopSubtitleLabelAnimationTypeNone = 0,
    MITShuttleStopSubtitleLabelAnimationTypeForward,
    MITShuttleStopSubtitleLabelAnimationTypeBackward
} MITShuttleStopSubtitleLabelAnimationType;

@interface MITShuttleRouteContainerViewController () <MITShuttleRouteViewControllerDataSource, MITShuttleRouteViewControllerDelegate, MITShuttleMapViewControllerDelegate>

@property (strong, nonatomic) MITShuttleMapViewController *mapViewController;
@property (strong, nonatomic) MITShuttleRouteViewController *routeViewController;
@property (copy, nonatomic) NSArray *stopViewControllers;

@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (weak, nonatomic) IBOutlet UIView *routeContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *stopsScrollView;

@property (strong, nonatomic) IBOutlet UIView *toolbarLabelView;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;

@property (strong, nonatomic) IBOutlet UIView *stopTitleView;
@property (weak, nonatomic) IBOutlet UILabel *stopTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *navigationBarExtensionView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewPortraitHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewLandscapeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBarExtensionViewHeightConstraint;

@property (nonatomic) UIInterfaceOrientation nibInterfaceOrientation;
@property (strong, nonatomic) NSDate *lastUpdatedDate;
@property (nonatomic) BOOL isUpdating;

@property (nonatomic) MITShuttleRouteContainerState previousState;
@property (nonatomic, getter = isRotating) BOOL rotating;

@end

@implementation MITShuttleRouteContainerViewController

#pragma mark - Init

- (instancetype)initWithRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    self = [self initWithNibName:[self nibNameForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation] bundle:nil];
    if (self) {
        _route = route;
        _stop = stop;
        _state = stop ? MITShuttleRouteContainerStateStop : MITShuttleRouteContainerStateRoute;
        _nibInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self setupChildViewControllers];
    }
    return self;
}

- (NSString *)nibNameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [NSString stringWithFormat:@"%@%@", NSStringFromClass([self class]), UIInterfaceOrientationIsLandscape(interfaceOrientation) ? @"-landscape": @""];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self displayAllChildViewControllers];
    [self layoutStopViews];
    [self setupToolbar];
    [self configureLayoutForState:self.state animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:(self.state != MITShuttleRouteContainerStateRoute) animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setNavigationBarExtended:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return;
    }
    self.rotating = YES;
    [self hideAllChildViewControllers];
    NSString *nibname = [self nibNameForInterfaceOrientation:toInterfaceOrientation];
    [[NSBundle mainBundle] loadNibNamed:nibname owner:self options:nil];
    self.nibInterfaceOrientation = toInterfaceOrientation;
    [self viewDidLoad];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.rotating = NO;
    [self configureLayoutForState:self.state animated:NO];
}

#pragma mark - Setup

- (void)setupChildViewControllers
{
    [self setupMapViewController];
    [self setupRouteViewController];
    [self setupStopViewControllers];
}

- (void)setupMapViewController
{
    self.mapViewController = [[MITShuttleMapViewController alloc] initWithRoute:self.route];
    self.mapViewController.delegate = self;
    self.mapViewController.stop = self.stop;
    [self.mapViewController setState:MITShuttleMapStateContracted];
}

- (void)setupRouteViewController
{
    self.routeViewController = [[MITShuttleRouteViewController alloc] initWithRoute:self.route];
    self.routeViewController.dataSource = self;
    self.routeViewController.delegate = self;
}

- (void)setupStopViewControllers
{
    NSArray *stops = [self.route.stops array];
    NSMutableArray *stopViewControllers = [NSMutableArray arrayWithCapacity:[stops count]];
    for (MITShuttleStop *stop in stops) {
        MITShuttleStopViewController *stopVC = [[MITShuttleStopViewController alloc] initWithStop:stop];
        [stopViewControllers addObject:stopVC];
    }
    self.stopViewControllers = [NSArray arrayWithArray:stopViewControllers];
}

- (void)setupToolbar
{
    UIBarButtonItem *toolbarLabelItem = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabelView];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace], toolbarLabelItem, [UIBarButtonItem flexibleSpace]]];
}

#pragma mark - Child View Controllers

- (void)displayAllChildViewControllers
{
    [self addViewOfChildViewController:self.mapViewController toView:self.mapContainerView];
    [self addViewOfChildViewController:self.routeViewController toView:self.routeContainerView];
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        [self addViewOfChildViewController:stopViewController toView:self.stopsScrollView];
    }
}

- (void)addViewOfChildViewController:(UIViewController *)childViewController toView:(UIView *)view
{
    [self addChildViewController:childViewController];
    childViewController.view.frame = view.bounds;
    [view addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
}

- (void)hideAllChildViewControllers
{
    [self hideChildViewController:self.mapViewController];
    [self hideChildViewController:self.routeViewController];
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        [self hideChildViewController:stopViewController];
    }
}

- (void)hideChildViewController:(UIViewController *)childViewController
{
    [childViewController willMoveToParentViewController:nil];
    [childViewController.view removeFromSuperview];
    [childViewController removeFromParentViewController];
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

- (void)setTitleForStop:(MITShuttleStop *)stop {
    self.title = stop.title;
    self.navigationItem.titleView = nil;
}

- (void)setStopSubtitleWithStop:(MITShuttleStop *)stop animationType:(MITShuttleStopSubtitleLabelAnimationType)animationType
{
    if (animationType == MITShuttleStopSubtitleLabelAnimationTypeNone) {
        self.stopSubtitleLabel.text = stop.title;
    } else {
        CGPoint stopSubtitleLabelCenter = self.stopSubtitleLabel.center;
        self.stopSubtitleLabel.translatesAutoresizingMaskIntoConstraints = YES;
        
        CGPoint initialTempLabelCenter;
        CGPoint finalSubtitleLabelCenter;
        switch (animationType) {
            case MITShuttleStopSubtitleLabelAnimationTypeForward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(kStopSubtitleAnimationSpan, 0));
                finalSubtitleLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                       CGAffineTransformMakeTranslation(-kStopSubtitleAnimationSpan, 0));
                break;
            case MITShuttleStopSubtitleLabelAnimationTypeBackward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(-kStopSubtitleAnimationSpan, 0));
                finalSubtitleLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                       CGAffineTransformMakeTranslation(kStopSubtitleAnimationSpan, 0));
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
            self.stopSubtitleLabel.center = finalSubtitleLabelCenter;
            self.stopSubtitleLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [tempLabel removeFromSuperview];
            self.stopSubtitleLabel.text = stop.title;
            [self.stopSubtitleLabel sizeToFit];
            self.stopSubtitleLabel.center = stopSubtitleLabelCenter;
            self.stopSubtitleLabel.alpha = 1;
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

#pragma mark - Last Updated

- (void)refreshLastUpdatedLabel
{
    NSString *lastUpdatedText;
    if (self.isUpdating) {
        lastUpdatedText = @"Updating...";
    } else {
        NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdatedDate
                                                                            toDate:[NSDate date]];
        lastUpdatedText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
    }
    self.lastUpdatedLabel.text = lastUpdatedText;
}

#pragma mark - Stop View Layout

- (void)setStop:(MITShuttleStop *)stop
{
    _stop = stop;
    self.mapViewController.stop = stop;
    [self configureStopViewControllerRefreshing];
}

- (void)layoutStopViews
{
    CGSize stopViewSize = self.stopsScrollView.frame.size;
    CGFloat xOffset = 0;
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        stopViewController.view.frame = CGRectMake(xOffset, 0, stopViewSize.width, stopViewSize.height);
        xOffset += stopViewSize.width;
    }
    self.stopsScrollView.contentSize = CGSizeMake(xOffset, stopViewSize.height);
}

- (void)selectStop:(MITShuttleStop *)stop
{
    NSInteger index = [self.route.stops indexOfObject:stop];
    CGFloat offset = self.stopsScrollView.frame.size.width * index;
    [self.stopsScrollView setContentOffset:CGPointMake(offset, 0) animated:NO];
}

- (void)didScrollToStop:(MITShuttleStop *)stop
{
    MITShuttleStopSubtitleLabelAnimationType animationType;
    NSInteger previousStopIndex = [self.route.stops indexOfObject:self.stop];
    NSInteger newStopIndex = [self.route.stops indexOfObject:stop];
    if (previousStopIndex < newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex > newStopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeNone;
    }
    [self setStopSubtitleWithStop:stop animationType:animationType];
    self.stop = stop;
}

- (MITShuttleStopViewController *)stopViewControllerForStop:(MITShuttleStop *)stop
{
    NSInteger stopIndex = [self.route.stops indexOfObject:stop];
    if (stopIndex >= 0 && stopIndex < [self.stopViewControllers count]) {
        return self.stopViewControllers[stopIndex];
    } else {
        return nil;
    }
}

#pragma mark - Stop Refreshing

- (void)configureStopViewControllerRefreshing
{
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        NSInteger index = [self.stopViewControllers indexOfObject:stopViewController];
        MITShuttleStop *stop = self.route.stops[index];
        stopViewController.shouldRefreshData = [self shouldRefreshStop:stop];
    }
}

- (BOOL)shouldRefreshStop:(MITShuttleStop *)stop
{
    NSInteger currentStopIndex = [self.route.stops indexOfObject:self.stop];
    NSInteger stopIndex = [self.route.stops indexOfObject:stop];
    return (ABS(currentStopIndex - stopIndex) <= 1);
}

#pragma mark - Map Tap Gesture Recognizer

- (IBAction)mapContainerViewTapped:(id)sender
{
    if (self.state != MITShuttleRouteContainerStateMap) {
        [self setState:MITShuttleRouteContainerStateMap animated:YES];
    }
}

#pragma mark - State Configuration

- (void)setState:(MITShuttleRouteContainerState)state
{
    [self setState:state animated:NO];
}

- (void)setState:(MITShuttleRouteContainerState)state animated:(BOOL)animated
{
    [self configureLayoutForState:state animated:animated];
    _previousState = _state;
    _state = state;
}

- (void)configureLayoutForState:(MITShuttleRouteContainerState)state animated:(BOOL)animated
{
    switch (state) {
        case MITShuttleRouteContainerStateRoute:
            [self configureLayoutForRouteStateAnimated:animated];
            break;
        case MITShuttleRouteContainerStateStop:
            [self configureLayoutForStopStateAnimated:animated];
            break;
        case MITShuttleRouteContainerStateMap:
            [self configureLayoutForMapStateAnimated:animated];
            break;
        default:
            break;
    }
}

- (void)configureLayoutForRouteStateAnimated:(BOOL)animated
{
    [self setTitleForRoute:self.route];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self setRouteViewHidden:NO];
    [self.view sendSubviewToBack:self.mapContainerView];
    
    self.routeContainerViewTopSpaceConstraint.constant = 0;
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        self.mapContainerViewPortraitHeightConstraint.constant = kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateRoute];
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setStopViewHidden:YES];
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
    
    [self.routeViewController.tableView reloadData];
}

- (void)configureLayoutForStopStateAnimated:(BOOL)animated
{
    [self setTitleForRoute:self.route stop:self.stop animated:animated];
    [self selectStop:self.stop];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self setStopViewHidden:NO];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        [self.view sendSubviewToBack:self.mapContainerView];
        self.mapContainerViewPortraitHeightConstraint.constant = kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateStop];
    }
    self.routeContainerViewTopSpaceConstraint.constant = CGRectGetMaxY(self.stopsScrollView.frame);
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:YES];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self layoutStopViews];
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
    
    MITShuttleStopViewController *stopViewController = [self stopViewControllerForStop:self.stop];
    [stopViewController.tableView reloadData];
}

- (void)configureLayoutForMapStateAnimated:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self.view bringSubviewToFront:self.mapContainerView];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        self.routeContainerViewTopSpaceConstraint.constant = CGRectGetHeight(self.view.frame) - kMapContainerViewEmbeddedHeightPortrait;
        self.mapContainerViewPortraitHeightConstraint.constant = CGRectGetHeight(self.view.frame);
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateMap];
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setRouteViewHidden:YES];
        [self setStopViewHidden:YES];
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
}

// In order for scrollsToTop to work within a container view controller,
// only one instance of UIScrollView may be in the view hierarchy and visible.
// Note: hidden property of scroll view's parent view does not matter,
// scroll view itself must be hidden

- (void)setRouteViewHidden:(BOOL)hidden
{
    self.routeContainerView.hidden =
    self.routeViewController.tableView.hidden = hidden;
}

- (void)setStopViewHidden:(BOOL)hidden
{
    self.stopsScrollView.hidden = hidden;
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        stopViewController.tableView.hidden = hidden;
    }
}

- (CGFloat)mapContainerViewLandscapeWidthForState:(MITShuttleRouteContainerState)state
{
    switch (state) {
        case MITShuttleRouteContainerStateMap:
            return CGRectGetMaxX(self.routeContainerView.frame);
        case MITShuttleRouteContainerStateRoute:
        case MITShuttleRouteContainerStateStop: {
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            return MAX(screenSize.width, screenSize.height) * kMapContainerViewEmbeddedWidthRatioLandscape;
        }
        default:
            return 0;
    }
}

- (NSTimeInterval)stateTransitionDuration
{
    return UIInterfaceOrientationIsLandscape(self.nibInterfaceOrientation) ? kStateTransitionDurationLandscape : kStateTransitionDurationPortrait;
}

#pragma mark - Navigation Bar Extension

- (void)setNavigationBarExtended:(BOOL)extended
{
    self.navigationBarExtensionViewHeightConstraint.constant = extended ? kNavigationBarStopStateExtension : 0;
    
    dispatch_block_t frameAdjustmentBlock = ^{
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        UIView *navigationBarBackgroundView = navigationBar.subviews[0];
        CGFloat navigationBarMaxY = CGRectGetMaxY(navigationBar.frame);
        CGRect frame = navigationBarBackgroundView.frame;
        frame.size.height = extended ? navigationBarMaxY + kNavigationBarStopStateExtension : navigationBarMaxY;
        navigationBarBackgroundView.frame = frame;
    };
    
    if (extended && self.isRotating) {
        // Wait until UINavigationBar frame adjustments are made as a result of the rotation
        // Otherwise, bottom shadow will appear in the middle of the extended bar during rotation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), frameAdjustmentBlock);
    } else {
        frameAdjustmentBlock();
    }
}

#pragma mark - MITShuttleRouteViewControllerDataSource

- (BOOL)isMapEmbeddedInRouteViewController:(MITShuttleRouteViewController *)routeViewController
{
    return self.state == MITShuttleRouteContainerStateRoute && UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation);
}

- (CGFloat)embeddedMapHeightForRouteViewController:(MITShuttleRouteViewController *)routeViewController
{
    return self.mapContainerView.frame.size.height;
}

#pragma mark - MITShuttleRouteViewControllerDelegate

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didSelectStop:(MITShuttleStop *)stop
{
    self.stop = stop;
    [self setState:MITShuttleRouteContainerStateStop animated:YES];
}

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didScrollToContentOffset:(CGPoint)contentOffset
{
    if ([self isMapEmbeddedInRouteViewController:self.routeViewController]) {
        CGRect frame = self.mapContainerView.frame;
        frame.origin.y = -contentOffset.y;
        self.mapContainerView.frame = frame;
    }
}

- (void)routeViewControllerDidBeginRefreshing:(MITShuttleRouteViewController *)routeViewController
{
    self.isUpdating = YES;
    [self refreshLastUpdatedLabel];
}

- (void)routeViewControllerDidEndRefreshing:(MITShuttleRouteViewController *)routeViewController
{
    self.isUpdating = NO;
    self.lastUpdatedDate = [NSDate date];
    [self refreshLastUpdatedLabel];
    [self.mapViewController routeUpdated];
}

- (void)routeViewControllerDidSelectMapPlaceholderCell:(MITShuttleRouteViewController *)routeViewController
{
    [self mapContainerViewTapped:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (scrollView == self.stopsScrollView) {
        NSInteger stopIndex = (*targetContentOffset).x / self.stopsScrollView.frame.size.width;
        MITShuttleStop *stop = self.route.stops[stopIndex];
        [self didScrollToStop:stop];
    }
}

#pragma mark - MITShuttleMapViewControllerDelegate Methods

- (void)shuttleMapViewControllerExitFullscreenButtonPressed:(MITShuttleMapViewController *)mapViewController
{
    if (self.state == MITShuttleRouteContainerStateMap) {
        [self setState:self.previousState animated:YES];
    }
}

@end
