#import "MITToursStopDetailContainerViewController.h"
#import "MITToursStopDetailViewController.h"

@interface MITToursStopDetailContainerViewController () <UIPageViewControllerDataSource>

@property (strong, nonatomic) NSArray *mainLoopStops;
@property (strong, nonatomic) NSArray *sideTripStops;
@property (nonatomic) NSUInteger mainLoopIndex;

@property (strong, nonatomic) UIPageViewController *pageViewController;

@end

@implementation MITToursStopDetailContainerViewController

- (instancetype)initWithTour:(MITToursTour *)tour stop:(MITToursStop *)stop nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.tour = tour;
        self.currentStop = stop;
    }
    return self;
}

- (void)setTour:(MITToursTour *)tour
{
    _tour = tour;
    self.mainLoopStops = [tour.mainLoopStops copy];
    self.sideTripStops = [tour.sideTripsStops copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createPageViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)createPageViewController
{
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.dataSource = self;

    UIViewController *currentPage = [self detailViewControllerForStop:self.currentStop];
    [self.pageViewController setViewControllers:@[currentPage] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    UIView *pageView = self.pageViewController.view;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:pageView];
    [self.pageViewController didMoveToParentViewController:self];
    
    NSDictionary *pageViewDict = NSDictionaryOfVariableBindings(pageView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageView]|" options:0 metrics:nil views:pageViewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[pageView]-48-|" options:0 metrics:nil views:pageViewDict]];
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITToursStop *currentStop = [self stopForViewController:viewController];
    NSInteger index = [self.mainLoopStops indexOfObject:currentStop];
    NSInteger prevIndex = (index + self.mainLoopStops.count - 1) % self.mainLoopStops.count;
    MITToursStop *prevStop = [self.mainLoopStops objectAtIndex:prevIndex];
    return [self detailViewControllerForStop:prevStop];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITToursStop *currentStop = [self stopForViewController:viewController];
    NSInteger index = [self.mainLoopStops indexOfObject:currentStop];
    NSInteger nextIndex = (index + 1) % self.mainLoopStops.count;
    MITToursStop *nextStop = [self.mainLoopStops objectAtIndex:nextIndex];
    return [self detailViewControllerForStop:nextStop];
}

#pragma mark - Helpers

- (MITToursStop *)stopForViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITToursStopDetailViewController class]]) {
        return ((MITToursStopDetailViewController *)viewController).stop;
    }
    return nil;
}

- (MITToursStopDetailViewController *)detailViewControllerForStop:(MITToursStop *)stop
{
    return [[MITToursStopDetailViewController alloc] initWithTour:self.tour stop:stop nibName:nil bundle:nil];
}

@end
