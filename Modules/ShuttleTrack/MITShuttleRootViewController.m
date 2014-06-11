#import "MITShuttleRootViewController.h"
#import "MITShuttleHomeViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleMapViewController.h"

@interface MITShuttleRootViewController () <MITShuttleHomeViewControllerDelegate, MITShuttleRouteViewControllerDelegate, MITShuttleMapViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UISplitViewController *splitViewController;

@property (nonatomic, strong) UINavigationController *masterNavigationController;
@property (nonatomic, strong) UINavigationController *detailNavigationController;

@property (nonatomic, readonly) UIViewController *masterViewController;

@property (nonatomic, strong) MITShuttleHomeViewController *homeViewController;
@property (nonatomic, weak) MITShuttleRouteViewController *routeViewController;
@property (nonatomic, strong) MITShuttleMapViewController *mapViewController;

@end

@implementation MITShuttleRootViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViewControllers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

#pragma mark - Setup

- (void)setupViewControllers
{
    [self setupHomeViewController];
    [self setupMapViewController];
    [self setupSplitViewController];
    [self configureNavigationBarSeparatorOverlay];
}

- (void)setupHomeViewController
{
    self.homeViewController = [[MITShuttleHomeViewController alloc] initWithNibName:nil bundle:nil];
    self.homeViewController.delegate = self;
    self.homeViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu"]
                                                                                                style:UIBarButtonItemStylePlain
                                                                                               target:self.navigationItem.leftBarButtonItem.target
                                                                                               action:self.navigationItem.leftBarButtonItem.action];
    
    self.masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.homeViewController];
    self.masterNavigationController.delegate = self;
}

- (void)setupMapViewController
{
    self.mapViewController = [[MITShuttleMapViewController alloc] initWithNibName:nil bundle:nil];
    self.mapViewController.delegate = self;
    self.detailNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];
}

- (void)setupSplitViewController
{
    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.viewControllers = @[self.masterNavigationController, self.detailNavigationController];
    self.splitViewController.delegate = self;
    
    [self addChildViewController:self.splitViewController];
    self.splitViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.splitViewController.view];
    [self.splitViewController didMoveToParentViewController:self];
}

- (void)configureNavigationBarSeparatorOverlay
{
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, 1, 64)];
    overlayView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:242.0/255 alpha:1];
    [self.splitViewController.view addSubview:overlayView];
}

#pragma mark - Master View Controller

- (UIViewController *)masterViewController
{
    return self.masterNavigationController.topViewController;
}

#pragma mark - MITShuttleMapViewController

- (void)setMapViewControllerRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    [self.mapViewController setRoute:route stop:stop];
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;  // show both view controllers in all orientations
}

#pragma mark - MITShuttleHomeViewControllerDelegate

- (void)shuttleHomeViewController:(MITShuttleHomeViewController *)viewController didSelectRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop
{
    if (!stop) {
        MITShuttleRouteViewController *routeViewController = [[MITShuttleRouteViewController alloc] initWithRoute:route];
        routeViewController.delegate = self;
        [self.masterNavigationController pushViewController:routeViewController animated:YES];
        self.routeViewController = routeViewController;
    }
    [self setMapViewControllerRoute:route stop:stop];
}

#pragma mark - MITShuttleRouteViewControllerDelegate

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didSelectStop:(MITShuttleStop *)stop
{
    [self setMapViewControllerRoute:routeViewController.route stop:stop];
}

#pragma mark - MITShuttleMapViewControllerDelegate

- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didSelectStop:(MITShuttleStop *)stop
{
    UIViewController *masterViewController = self.masterViewController;
    if (masterViewController == self.homeViewController) {
        // TODO: determine behavior here. should we only mark selection if a "nearest stop" was selected? how do we know route context?
    } else if (masterViewController == self.routeViewController) {
        [self.routeViewController highlightStop:stop];
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationController == self.masterNavigationController) {
        // If popping back to home view controller, clear route and stop state from map
        if (viewController == self.homeViewController) {
            [self setMapViewControllerRoute:nil stop:nil];
        }
    }
}

@end
