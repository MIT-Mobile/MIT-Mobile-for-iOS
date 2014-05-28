#import "MITShuttleRouteContainerViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "UIKit+MITAdditions.h"
#import "NSDateFormatter+RelativeString.h"

@interface MITShuttleRouteContainerViewController () <MITShuttleRouteViewControllerDataSource, MITShuttleRouteViewControllerDelegate>

@property (strong, nonatomic) MITShuttleMapViewController *mapViewController;
@property (strong, nonatomic) MITShuttleRouteViewController *routeViewController;
@property (copy, nonatomic) NSArray *stopViewControllers;

@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (weak, nonatomic) IBOutlet UIView *routeContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *stopsScrollView;
@property (strong, nonatomic) IBOutlet UIView *toolbarLabelView;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;

@property (nonatomic) UIInterfaceOrientation nibInterfaceOrientation;
@property (strong, nonatomic) NSDate *lastUpdatedDate;
@property (nonatomic) BOOL isUpdating;

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
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return;
    }
    [self hideAllChildViewControllers];
    NSString *nibname = [self nibNameForInterfaceOrientation:toInterfaceOrientation];
    [[NSBundle mainBundle] loadNibNamed:nibname owner:self options:nil];
    self.nibInterfaceOrientation = toInterfaceOrientation;
    [self viewDidLoad];
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
//    childViewController.view.backgroundColor = [self randomColor];
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
            self.routeContainerView.hidden = NO;
            self.stopsScrollView.hidden = YES;
            [self.navigationController setToolbarHidden:NO animated:animated];
            break;
        case MITShuttleRouteContainerStateStop:
            self.routeContainerView.hidden = YES;
            self.stopsScrollView.hidden = NO;
            [self.navigationController setToolbarHidden:YES animated:animated];
            break;
        case MITShuttleRouteContainerStateMap:
            [self.navigationController setToolbarHidden:YES animated:animated];
            break;
        default:
            break;
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
    [self configureLayoutForState:MITShuttleRouteContainerStateStop animated:YES];
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

#pragma mark - Test code - to be removed

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@end
