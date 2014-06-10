#import "MITShuttleRootViewController.h"
#import "MITShuttleHomeViewController.h"
#import "MITShuttleRouteViewController.h"
#import "MITShuttleMapViewController.h"

@interface MITShuttleRootViewController ()

@property (nonatomic, strong) UISplitViewController *splitViewController;

@property (nonatomic, strong) UINavigationController *masterNavigationController;
@property (nonatomic, strong) UINavigationController *detailNavigationController;

@property (nonatomic, strong) MITShuttleHomeViewController *homeViewController;
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
    [self.navigationController setToolbarHidden:YES animated:animated];
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
    UIBarButtonItem *menuButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu"] style:UIBarButtonItemStylePlain target:self.navigationItem.leftBarButtonItem.target action:self.navigationItem.leftBarButtonItem.action];
    self.homeViewController.navigationItem.leftBarButtonItem = menuButtonItem;
    self.masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.homeViewController];
}

- (void)setupMapViewController
{
    self.mapViewController = [[MITShuttleMapViewController alloc] initWithNibName:nil bundle:nil];
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

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;  // show both view controllers in all orientations
}

@end
