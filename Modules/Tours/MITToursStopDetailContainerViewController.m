#import "MITToursStopDetailContainerViewController.h"
#import "MITToursStopDetailViewController.h"

@interface MITToursStopDetailContainerViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSArray *mainLoopStops;
@property (strong, nonatomic) NSArray *sideTripStops;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

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
    [self setupMainLoopCycleButtons];
    [self configureForStop:self.currentStop];
}

- (void)createPageViewController
{
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;

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

- (void)setupMainLoopCycleButtons
{
    UIBarButtonItem *upButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/map_disclosure_arrow"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(displayNextStop)];
    UIBarButtonItem *downButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/map_disclosure_arrow"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(displayPreviousStop)];
    self.mainLoopCycleButtons = @[upButton, downButton];
}

#pragma mark - Configuration for Stop

- (BOOL)isMainLoopStop:(MITToursStop *)stop
{
    return [self.mainLoopStops containsObject:self.currentStop];
}

- (void)configureForStop:(MITToursStop *)stop
{
    self.currentStop = stop;
    [self configureNavigationForStop:stop];
}

- (void)configureNavigationForStop:(MITToursStop *)stop
{
    NSInteger mainLoopIndex = [self.mainLoopStops indexOfObject:stop];
    if (mainLoopIndex != NSNotFound) {
        self.title = [NSString stringWithFormat:@"Main Loop %d of %d", mainLoopIndex + 1, self.mainLoopStops.count];
        [self.navigationItem setRightBarButtonItems:self.mainLoopCycleButtons animated:YES];
    } else {
        self.title = @"Side Stop";
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
    }
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITToursStop *currentStop = [self stopForViewController:viewController];
    NSInteger index = [self.mainLoopStops indexOfObject:currentStop];
    if (index != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:index];
        MITToursStop *prevStop = [self.mainLoopStops objectAtIndex:prevIndex];
        return [self detailViewControllerForStop:prevStop];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITToursStop *currentStop = [self stopForViewController:viewController];
    NSInteger index = [self.mainLoopStops indexOfObject:currentStop];
    if (index != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:index];
        MITToursStop *nextStop = [self.mainLoopStops objectAtIndex:nextIndex];
        return [self detailViewControllerForStop:nextStop];
    }
    return nil;
}

#pragma mark - UIPageViewControllerDelegateMethods

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    MITToursStop *newStop = [self stopForViewController:pendingViewControllers[0]];
    [self configureForStop:newStop];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSLog(@"Did finish animating!");
}

#pragma mark - Detail View Controllers

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

#pragma mark - Cycling Between Stops

- (void)displayNextStop
{
    NSInteger currentIndex = [self.mainLoopStops indexOfObject:self.currentStop];
    if (currentIndex != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:currentIndex];
        MITToursStop *nextStop = [self.mainLoopStops objectAtIndex:nextIndex];
        [self transitionToStop:nextStop];
    }
}

- (void)displayPreviousStop
{
    NSInteger currentIndex = [self.mainLoopStops indexOfObject:self.currentStop];
    if (currentIndex != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:currentIndex];
        MITToursStop *prevStop = [self.mainLoopStops objectAtIndex:prevIndex];
        [self transitionToStop:prevStop];
    }
}

- (void)transitionToStop:(MITToursStop *)stop
{
    NSInteger currentIndex = [self.mainLoopStops indexOfObject:self.currentStop];
    NSInteger newIndex = [self.mainLoopStops indexOfObject:stop];
    
    // If the new stop is immediately before or after the current one in main loop order, then
    // we want the transition to be animated as if the user had swiped.
    BOOL animated = NO;
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    if (currentIndex != NSNotFound && newIndex != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:currentIndex];
        NSInteger prevIndex = [self indexBeforeIndex:currentIndex];
        if (newIndex == nextIndex) {
            animated = YES;
        } else if (newIndex == prevIndex) {
            animated = YES;
            direction = UIPageViewControllerNavigationDirectionReverse;
        }
    }
    
    MITToursStopDetailViewController *detailViewController = [self detailViewControllerForStop:stop];
    __weak MITToursStopDetailContainerViewController *weakSelf = self;
    [self.pageViewController setViewControllers:@[detailViewController] direction:direction animated:animated completion:^(BOOL finished) {
        // Programmatic transitions do not trigger the delegate methods, so we need to manually reconfigure for the new stop after we are done.
        [weakSelf configureForStop:stop];
    }];
}

#pragma mark - Main Loop Index Math

- (NSInteger)indexAfterIndex:(NSInteger)index
{
    return (index + 1) % self.mainLoopStops.count;
}

- (NSInteger)indexBeforeIndex:(NSInteger)index
{
    return (index + self.mainLoopStops.count - 1 ) % self.mainLoopStops.count;
}

@end
