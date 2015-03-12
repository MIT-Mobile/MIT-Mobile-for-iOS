#import "MITMartyDetailContainerViewController.h"
#import "MITToursStopDetailViewController.h"

@interface MITMartyDetailContainerViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, MITToursStopDetailViewControllerDelegate>

@property (strong, nonatomic) NSArray *mainLoopStops;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

@property (strong, nonatomic) MITToursStop *mostRecentMainLoopStop;

@property (nonatomic) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *inputViews;

@end

@implementation MITMartyDetailContainerViewController

- (instancetype)initWithTour:(MITToursTour *)tour stop:(MITToursStop *)stop nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.tour = tour;
        self.currentStop = stop;
        if ([stop isMainLoopStop]) {
            self.mostRecentMainLoopStop = stop;
        }
        else {
            self.mostRecentMainLoopStop = self.mainLoopStops[0];
        }
    }
    return self;
}

- (void)setTour:(MITToursTour *)tour
{
    _tour = tour;
    self.mainLoopStops = [tour.mainLoopStops copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupToolbar];
    [self createPageViewController];
    [self setupMainLoopCycleButtons];
    [self configureForStop:self.currentStop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
}

- (void)setupToolbar
{
    UIBarButtonItem *directionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStylePlain target:self action:@selector(directionsButtonPressed:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[flexibleSpace, directionsButton];
}

- (void)createPageViewController
{
    NSDictionary *pageViewControllerOptions = @{UIPageViewControllerOptionInterPageSpacingKey : [NSNumber numberWithFloat:50.0]};
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:pageViewControllerOptions];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    UIView *pageView = self.pageViewController.view;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:pageView];
    [self.pageViewController didMoveToParentViewController:self];
    
    UIViewController *currentPage = [self detailViewControllerForStop:self.currentStop];
    [self.pageViewController setViewControllers:@[currentPage] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    NSDictionary *pageViewDict = NSDictionaryOfVariableBindings(pageView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageView]|" options:0 metrics:nil views:pageViewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[pageView]|" options:0 metrics:nil views:pageViewDict]];
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.inputViews addObject:self.pageViewController.view];
}

- (void)setupMainLoopCycleButtons
{
    UIImage *upButtonImage = [UIImage imageNamed:MITImageToursPadChevronUp];
    UIImage *downButtonImage = [UIImage imageNamed:MITImageToursPadChevronDown];

    CGFloat spacing = 10;
    CGFloat width = upButtonImage.size.width + downButtonImage.size.width + spacing;
    CGFloat height = MAX(upButtonImage.size.height, downButtonImage.size.height);
    CGRect parentFrame = CGRectMake(0, 0, width, height);
    UIView *parentView = [[UIView alloc] initWithFrame:parentFrame];
    
    UIButton *upButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [upButton setImage:upButtonImage forState:UIControlStateNormal];
    [upButton addTarget:self action:@selector(displayPreviousStop) forControlEvents:UIControlEventTouchUpInside];

    UIButton *downButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downButton setImage:downButtonImage forState:UIControlStateNormal];
    [downButton addTarget:self action:@selector(displayNextStop) forControlEvents:UIControlEventTouchUpInside];
    
    [parentView addSubview:upButton];
    [parentView addSubview:downButton];
    
    upButton.frame = CGRectMake(0,
                                0.5 * (height - upButtonImage.size.height),
                                upButtonImage.size.width,
                                upButtonImage.size.height);
    downButton.frame = CGRectMake(width - downButtonImage.size.width,
                                  0.5 * (height - downButtonImage.size.height),
                                  downButtonImage.size.width,
                                  downButtonImage.size.height);

    UIBarButtonItem *buttonContainerItem = [[UIBarButtonItem alloc] initWithCustomView:parentView];
    
    self.mainLoopCycleButtons = @[buttonContainerItem];
    
    [self.inputViews addObject:upButton];
    [self.inputViews addObject:downButton];
}

#pragma mark - Transition

- (NSMutableArray *)inputViews {
    if (_inputViews == nil) {
        _inputViews = [[NSMutableArray alloc] init];
    }
    return _inputViews;
}

- (void)setIsTransitioning:(BOOL)isTransitioning {
    if (isTransitioning != _isTransitioning) {
        _isTransitioning = isTransitioning;
        for (UIView *view in self.inputViews) {
            view.userInteractionEnabled = !isTransitioning;
        }
    }
}

#pragma mark - Configuration for Stop

- (BOOL)isMainLoopStop:(MITToursStop *)stop
{
    return [self.mainLoopStops containsObject:self.currentStop];
}

- (void)configureForStop:(MITToursStop *)stop
{
    self.currentStop = stop;
    [self configureNavigationForStop:stop shouldPutNameInTitle:NO];
}

- (void)configureNavigationForStop:(MITToursStop *)stop shouldPutNameInTitle:(BOOL)shouldPutNameInTitle
{
    NSInteger mainLoopIndex = [self.mainLoopStops indexOfObject:stop];
    if (mainLoopIndex != NSNotFound) {
        if (shouldPutNameInTitle) {
            self.title = stop.title;
        } else {
            self.title = [NSString stringWithFormat:@"Main Loop %ld of %lu", (long)mainLoopIndex + 1, (unsigned long)self.mainLoopStops.count];
        }
        [self.navigationItem setRightBarButtonItems:self.mainLoopCycleButtons animated:YES];
    } else {
        if (shouldPutNameInTitle) {
            self.title = [NSString stringWithFormat:@"Side Trip - %@", stop.title];
        } else {
            self.title = @"Side Trip";
        }
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

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.isTransitioning = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        UIViewController *currentViewController = self.pageViewController.viewControllers[0];
        MITToursStop *newStop = [self stopForViewController:currentViewController];
        [self configureForStop:newStop];
    }
    self.isTransitioning = NO;
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
    MITToursStopDetailViewController *detailViewController = [[MITToursStopDetailViewController alloc] initWithTour:self.tour stop:stop nibName:nil bundle:nil];
    detailViewController.delegate = self;
    return detailViewController;
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
    if (self.isTransitioning) {
        return;
    }
    self.isTransitioning = YES;
    
    if ([stop isMainLoopStop]) {
        self.mostRecentMainLoopStop = stop;
    }
    
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
    __weak MITMartyDetailContainerViewController *weakSelf = self;
    [self.pageViewController setViewControllers:@[detailViewController] direction:direction animated:animated completion:^(BOOL finished) {
        // Programmatic transitions do not trigger the delegate methods, so we need to manually reconfigure for the new stop after we are done.
        [weakSelf configureForStop:stop];
        weakSelf.isTransitioning = NO;
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

- (MITToursStop *)mainLoopStopAfterStop:(MITToursStop *)stop
{
    NSInteger index = [self.mainLoopStops indexOfObject:stop];
    index = [self indexAfterIndex:index];
    return self.mainLoopStops[index];
}

- (MITToursStop *)mainLoopStopBeforeStop:(MITToursStop *)stop
{
    NSInteger index = [self.mainLoopStops indexOfObject:stop];
    index = [self indexBeforeIndex:index];
    return self.mainLoopStops[index];
}

#pragma mark - MITToursStopDetailViewControllerDelegate Methods

- (void)stopDetailViewControllerTitleDidScrollBelowTitle:(MITToursStopDetailViewController *)detailViewController
{
    UIViewController *currentViewController = self.pageViewController.viewControllers[0];
    if (detailViewController == currentViewController) {
        MITToursStop *stop = [self stopForViewController:detailViewController];
        [self configureNavigationForStop:stop shouldPutNameInTitle:YES];
    }
}

- (void)stopDetailViewControllerTitleDidScrollAboveTitle:(MITToursStopDetailViewController *)detailViewController
{    UIViewController *currentViewController = self.pageViewController.viewControllers[0];
    if (detailViewController == currentViewController) {
        MITToursStop *stop = [self stopForViewController:detailViewController];
        [self configureNavigationForStop:stop shouldPutNameInTitle:NO];
    }
}

- (void)stopDetailViewController:(MITToursStopDetailViewController *)detailViewController didSelectStop:(MITToursStop *)stop
{
    if (stop != self.currentStop) {
        [self transitionToStop:stop];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.pageViewController.view setNeedsLayout];
}

#pragma mark - Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger supportedOrientations = UIInterfaceOrientationMaskPortrait;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        supportedOrientations |= UIInterfaceOrientationMaskLandscapeLeft;
        supportedOrientations |= UIInterfaceOrientationMaskLandscapeRight;
    }
    return supportedOrientations;
}

- (BOOL)shouldAutorotate
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

@end
