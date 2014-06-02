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

typedef enum {
    MITShuttleStopSubtitleLabelAnimationTypeNone = 0,
    MITShuttleStopSubtitleLabelAnimationTypeForward,
    MITShuttleStopSubtitleLabelAnimationTypeBackward
} MITShuttleStopSubtitleLabelAnimationType;

@interface MITShuttleRouteContainerViewController () <MITShuttleRouteViewControllerDataSource, MITShuttleRouteViewControllerDelegate>

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

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routeContainerViewTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewPortraitHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapContainerViewLandscapeWidthConstraint;

@property (nonatomic) UIInterfaceOrientation nibInterfaceOrientation;
@property (strong, nonatomic) NSDate *lastUpdatedDate;
@property (nonatomic) BOOL isUpdating;

@property (nonatomic) MITShuttleRouteContainerState previousState;

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
    [self hideAllChildViewControllers];
    NSString *nibname = [self nibNameForInterfaceOrientation:toInterfaceOrientation];
    [[NSBundle mainBundle] loadNibNamed:nibname owner:self options:nil];
    self.nibInterfaceOrientation = toInterfaceOrientation;
    [self viewDidLoad];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self configureLayoutForState:self.state animated:NO];
}

#pragma mark - Setup

- (void)setupChildViewControllers
{
    self.mapViewController = [[MITShuttleMapViewController alloc] initWithRoute:self.route];
    [self setupRouteViewController];
    [self setupStopViewControllers];
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
        [stopViewControllers addObject:[[MITShuttleStopViewController alloc] initWithStop:stop]];
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
//    [self addViewOfChildViewController:self.mapViewController toView:self.mapContainerView];
    [self addViewOfChildViewController:self.routeViewController toView:self.routeContainerView];
    for (MITShuttleStopViewController *stopViewController in self.stopViewControllers) {
        [self addViewOfChildViewController:stopViewController toView:self.stopsScrollView];
    }
}

- (void)addViewOfChildViewController:(UIViewController *)childViewController toView:(UIView *)view
{
    [self addChildViewController:childViewController];
    childViewController.view.frame = view.bounds;
    if ([childViewController isKindOfClass:[MITShuttleStopViewController class]]) {
        childViewController.view.backgroundColor = [self randomColor];
    }
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
}

- (void)setTitleForRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    self.navigationItem.titleView = self.stopTitleView;
    self.stopTitleLabel.text = route.title;
    [self setStopSubtitleWithStop:stop animationType:MITShuttleStopSubtitleLabelAnimationTypeNone];
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
        UILabel *tempLabel = [[UILabel alloc] initWithFrame:self.stopSubtitleLabel.frame];
        tempLabel.backgroundColor = [UIColor clearColor];
        tempLabel.textAlignment = NSTextAlignmentCenter;
        tempLabel.textColor = self.stopSubtitleLabel.textColor;
        tempLabel.font = self.stopSubtitleLabel.font;
        tempLabel.text = stop.title;
        [tempLabel sizeToFit];
        tempLabel.center = initialTempLabelCenter;
        tempLabel.alpha = 0;
        [self.stopTitleView addSubview:tempLabel];
        [UIView animateWithDuration:0.3 animations:^{
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

#pragma mark - Map Tap Gesture Recognizer (TEMP)

- (IBAction)mapContainerViewTapped:(id)sender
{
    if (self.state == MITShuttleRouteContainerStateMap) {
        [self setState:self.previousState animated:YES];
    } else {
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
        self.mapContainerViewLandscapeWidthConstraint.constant = CGRectGetMaxX(self.routeContainerView.frame) * kMapContainerViewEmbeddedWidthRatioLandscape;
    }

    dispatch_block_t animationBlock = ^{
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setStopViewHidden:YES];
    };
    
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
    [self setTitleForRoute:self.route stop:self.stop];
    [self selectStop:self.stop];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self setStopViewHidden:NO];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        [self.view sendSubviewToBack:self.mapContainerView];
        self.mapContainerViewPortraitHeightConstraint.constant = kMapContainerViewEmbeddedHeightPortrait;
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = CGRectGetMaxX(self.stopsScrollView.frame) * kMapContainerViewEmbeddedWidthRatioLandscape;
    }
    self.routeContainerViewTopSpaceConstraint.constant = CGRectGetMaxY(self.stopsScrollView.frame);

    dispatch_block_t animationBlock = ^{
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setRouteViewHidden:YES];
    };
    
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

- (void)configureLayoutForMapStateAnimated:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self.view bringSubviewToFront:self.mapContainerView];
    
    if (UIInterfaceOrientationIsPortrait(self.nibInterfaceOrientation)) {
        self.routeContainerViewTopSpaceConstraint.constant = CGRectGetHeight(self.view.frame) - kMapContainerViewEmbeddedHeightPortrait;
        self.mapContainerViewPortraitHeightConstraint.constant = CGRectGetHeight(self.view.frame);
    } else {
        self.mapContainerViewLandscapeWidthConstraint.constant = CGRectGetMaxX(self.routeContainerView.frame);
    }

    dispatch_block_t animationBlock = ^{
        [self.view layoutIfNeeded];
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self setRouteViewHidden:YES];
        [self setStopViewHidden:YES];
    };

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

// In order for scrollsToTop to work with in a container view controller,
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

- (NSTimeInterval)stateTransitionDuration
{
    return UIInterfaceOrientationIsLandscape(self.nibInterfaceOrientation) ? kStateTransitionDurationLandscape : kStateTransitionDurationPortrait;
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
}

- (void)routeViewControllerDidSelectMapPlaceholderCell:(MITShuttleRouteViewController *)routeViewController
{
    [self mapContainerViewTapped:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewMovementDidEnd];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewMovementDidEnd];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollViewMovementDidEnd];
    }
}

- (void)scrollViewMovementDidEnd
{
    NSInteger stopIndex = self.stopsScrollView.contentOffset.x / self.stopsScrollView.frame.size.width;
    MITShuttleStop *stop = self.route.stops[stopIndex];
    MITShuttleStopSubtitleLabelAnimationType animationType;
    NSInteger previousStopIndex = [self.route.stops indexOfObject:self.stop];
    if (previousStopIndex < stopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeForward;
    } else if (previousStopIndex > stopIndex) {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeBackward;
    } else {
        animationType = MITShuttleStopSubtitleLabelAnimationTypeNone;
    }
    [self setStopSubtitleWithStop:stop animationType:animationType];
    self.stop = stop;
}

#pragma mark - Test code - to be removed

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@end
