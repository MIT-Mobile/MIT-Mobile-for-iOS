#import "MITShuttleRouteContainerViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopPredictionLoader.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"
#import "MITExtendedNavBarView.h"
#import "UINavigationBar+ExtensionPrep.h"

static const NSTimeInterval kStateTransitionDurationPortrait = 0.5;
static const NSTimeInterval kStateTransitionDurationLandscape = 0.3;

static const CGFloat kMapContainerViewEmbeddedHeightPortrait = 190.0;
static const CGFloat kMapContainerViewEmbeddedWidthRatioLandscape = 320.0 / 568.0;

static const CGFloat kStopSubtitleAnimationSpan = 40.0;
static const NSTimeInterval kStopSubtitleAnimationDuration = 0.3;

static const CGFloat kNavigationBarStopStateExtensionHeight = 14.0;

typedef NS_ENUM(NSUInteger, MITShuttleStopSubtitleLabelAnimationType) {
    MITShuttleStopSubtitleLabelAnimationTypeNone = 0,
    MITShuttleStopSubtitleLabelAnimationTypeForward,
    MITShuttleStopSubtitleLabelAnimationTypeBackward
};

@interface MITShuttleRouteContainerViewController () <MITShuttleRouteViewControllerDataSource, MITShuttleRouteViewControllerDelegate, MITShuttleMapViewControllerDelegate>

@property (strong, nonatomic) MITShuttleMapViewController *mapViewController;
@property (strong, nonatomic) MITShuttleRouteViewController *routeViewController;
@property (copy, nonatomic) NSArray *stopViewControllers;

@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (weak, nonatomic) IBOutlet UIView *routeContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *stopsScrollView;

@property (strong, nonatomic) IBOutlet UIView *stopTitleView;
@property (weak, nonatomic) IBOutlet UILabel *stopTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopSubtitleLabel;
@property (weak, nonatomic) IBOutlet MITExtendedNavBarView *navigationBarExtensionView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewZeroHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewPortraitHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewLandscapeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewLandscapeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stopsScrollViewLandscapeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewLandscapeTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stopsScrollViewLandscapeTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBarExtensionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBarExtensionViewTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stopSubtitleLabelCenterAlignmentConstraint;

@property (nonatomic) UIInterfaceOrientation nibInterfaceOrientation;

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
    [self setupNavBar];
    [self displayAllChildViewControllers];
    [self layoutStopViews];
    if (!self.isRotating) {
        [self configureLayoutForState:self.state animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    if (self.state == MITShuttleRouteContainerStateStop) {
        [self configureLayoutForState:self.state animated:NO];
        [self layoutStopViews];
        [self configureStopViewControllerRefreshing];
    }
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

- (void)setupNavBar
{
    [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:[UIColor whiteColor]];
    
    self.navigationBarExtensionViewHeightConstraint.constant = kNavigationBarStopStateExtensionHeight;
}

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
        MITShuttleStopViewController *stopVC = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                              stop:stop
                                                                                             route:self.route];
        stopVC.predictionLoader.shouldRefreshPredictions = NO;
        stopVC.viewOption = MITShuttleStopViewOptionAll;
        [stopViewControllers addObject:stopVC];
    }
    self.stopViewControllers = [NSArray arrayWithArray:stopViewControllers];
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
    childViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
        CGPoint initialTempLabelCenter;
        switch (animationType) {
            case MITShuttleStopSubtitleLabelAnimationTypeForward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(kStopSubtitleAnimationSpan, 0));
                self.stopSubtitleLabelCenterAlignmentConstraint.constant = kStopSubtitleAnimationSpan;
                break;
            case MITShuttleStopSubtitleLabelAnimationTypeBackward:
                initialTempLabelCenter = CGPointApplyAffineTransform(stopSubtitleLabelCenter,
                                                                     CGAffineTransformMakeTranslation(-kStopSubtitleAnimationSpan, 0));
                self.stopSubtitleLabelCenterAlignmentConstraint.constant = -kStopSubtitleAnimationSpan;
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

#pragma mark - Stop View Layout

- (void)setStop:(MITShuttleStop *)stop
{
    _stop = stop;
    self.mapViewController.stop = stop;
    
    if (self.state == MITShuttleRouteContainerStateStop) {
        [self.mapViewController centerToShuttleStop:stop animated:YES];
    }
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
    
    if (self.stop) {
        [self scrollToStop:self.stop animated:NO];
    }
}

- (void)scrollToStop:(MITShuttleStop *)stop animated:(BOOL)animated
{
    NSInteger index = [self.route.stops indexOfObject:stop];
    CGFloat offset = self.stopsScrollView.frame.size.width * index;
    [self.stopsScrollView setContentOffset:CGPointMake(offset, 0) animated:animated];
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
        stopViewController.predictionLoader.shouldRefreshPredictions = [self shouldRefreshStop:stop];
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
    _state = state;
}

- (void)configureLayoutForState:(MITShuttleRouteContainerState)state animated:(BOOL)animated
{
    switch (state) {
        case MITShuttleRouteContainerStateRoute:
            [self configureLayoutForRouteStateAnimated:animated];
            self.mapViewController.shouldUsePinAnnotations = NO;
            break;
        case MITShuttleRouteContainerStateStop:
            [self configureLayoutForStopStateAnimated:animated];
            self.mapViewController.shouldUsePinAnnotations = NO;
            break;
        case MITShuttleRouteContainerStateMap:
            [self configureLayoutForMapStateAnimated:animated];
            self.mapViewController.shouldUsePinAnnotations = YES;
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
    [self.view sendSubviewToBack:self.mapContainerView];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        self.routeContainerViewTopSpaceConstraint.constant = 0;
        self.routeContainerViewTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.routeContainerViewZeroHeightConstraint.priority = UILayoutPriorityDefaultLow;
        self.mapContainerViewPortraitHeightConstraint.constant = kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateRoute];
        self.routeContainerViewLandscapeTrailingSpaceConstraint.priority =
        self.stopsScrollViewLandscapeTrailingSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.routeContainerViewLandscapeWidthConstraint.priority =
        self.stopsScrollViewLandscapeWidthConstraint.priority = UILayoutPriorityDefaultLow;
    }

    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        [self.mapViewController setMapToolBarHidden:YES];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setStopViewHidden:YES];
        [self.mapViewController setState:MITShuttleMapStateContracted];
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
}

- (void)configureLayoutForStopStateAnimated:(BOOL)animated
{
    [self setTitleForRoute:self.route stop:self.stop animated:animated];
    [self setStopViewHidden:NO];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        [self.view sendSubviewToBack:self.mapContainerView];

        self.routeContainerViewTopSpaceConstraint.priority = UILayoutPriorityDefaultLow;
        self.routeContainerViewZeroHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        self.mapContainerViewPortraitHeightConstraint.constant = kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateStop];
        self.routeContainerViewLandscapeTrailingSpaceConstraint.priority =
        self.stopsScrollViewLandscapeTrailingSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.routeContainerViewLandscapeWidthConstraint.priority =
        self.stopsScrollViewLandscapeWidthConstraint.priority = UILayoutPriorityDefaultLow;
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:YES];
        [self.mapViewController setMapToolBarHidden:YES];
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self layoutStopViews];
        [self setRouteViewHidden:YES];
        [self.mapViewController setState:MITShuttleMapStateContracted];
        MITShuttleStopViewController *stopViewController = [self stopViewControllerForStop:self.stop];
        [stopViewController.tableView reloadData];
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
    
    [self configureStopViewControllerRefreshing];
}

- (void)configureLayoutForMapStateAnimated:(BOOL)animated
{
    [self.view bringSubviewToFront:self.mapContainerView];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        self.routeContainerViewTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.routeContainerViewZeroHeightConstraint.priority = UILayoutPriorityDefaultLow;
        self.routeContainerViewTopSpaceConstraint.constant = CGRectGetHeight(self.view.frame) - kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = [self mapContainerViewLandscapeWidthForState:MITShuttleRouteContainerStateMap];
        self.routeContainerViewLandscapeTrailingSpaceConstraint.priority =
        self.stopsScrollViewLandscapeTrailingSpaceConstraint.priority = UILayoutPriorityDefaultLow;
        self.routeContainerViewLandscapeWidthConstraint.priority =
        self.stopsScrollViewLandscapeWidthConstraint.priority = UILayoutPriorityDefaultHigh;
    }
    
    dispatch_block_t animationBlock = ^{
        [self setNavigationBarExtended:NO];
        
        // Updating this constraint outside of animation block triggers a constraint exception
        if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
            self.mapContainerViewPortraitHeightConstraint.constant = CGRectGetHeight(self.view.frame);
        }
        [self.mapViewController setMapToolBarHidden:NO];
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

- (void)routeViewControllerDidRefresh:(MITShuttleRouteViewController *)routeViewController
{
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollingDidEnd];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollingDidEnd];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollingDidEnd];
}

- (void)scrollingDidEnd
{
    [self configureStopViewControllerRefreshing];
}

#pragma mark - MITShuttleMapViewControllerDelegate Methods

- (void)shuttleMapViewControllerExitFullscreenButtonPressed:(MITShuttleMapViewController *)mapViewController
{
    if (self.state == MITShuttleRouteContainerStateMap) {
        self.mapViewController.stop = nil;
        // Always return to route state listing the stops regardless of previous state.
        [self setState:MITShuttleRouteContainerStateRoute animated:YES];
    }
}

- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didClickCalloutForStop:(MITShuttleStop *)stop
{
    self.stop = stop;
    [self setState:MITShuttleRouteContainerStateStop animated:YES];
}

@end
