#import "MITMobiusDetailContainerViewController.h"
#import "MITMobiusDetailTableViewController.h"

@interface MITMobiusDetailContainerViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSArray *resources;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

@property (strong, nonatomic) MITMobiusResource *currentResource;

@property (nonatomic) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *inputViews;

@end

@implementation MITMobiusDetailContainerViewController

- (instancetype)initWithResource:(MITMobiusResource *)resource resources:(NSArray *)resources
{
    if (self) {
        self.currentResource = resource;
        self.resources = resources;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createPageViewController];
    [self setupMainLoopCycleButtons];
    [self configureForResource:self.currentResource];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
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
    
    UIViewController *currentPage = [self detailViewControllerForResource:self.currentResource];
    [self.pageViewController setViewControllers:@[currentPage] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    NSDictionary *metrics = @{
                              @"padding" : @(self.navigationController.navigationBar.frame.size.height + 10)
                              };
    
    NSDictionary *pageViewDict = NSDictionaryOfVariableBindings(pageView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageView]|" options:0 metrics:nil views:pageViewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-padding-[pageView]|" options:0 metrics:metrics views:pageViewDict]];

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
    [upButton addTarget:self action:@selector(displayPreviousResource) forControlEvents:UIControlEventTouchUpInside];

    UIButton *downButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downButton setImage:downButtonImage forState:UIControlStateNormal];
    [downButton addTarget:self action:@selector(displayNextResource) forControlEvents:UIControlEventTouchUpInside];
    
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

#pragma mark - Configuration for Resource

- (void)configureForResource:(MITMobiusResource *)resource
{
    self.currentResource = resource;
    [self configureNavigationForResource:resource shouldPutNameInTitle:NO];
}

- (void)configureNavigationForResource:(MITMobiusResource *)resource shouldPutNameInTitle:(BOOL)shouldPutNameInTitle
{
    NSInteger resourceIndex = [self indexOfResource:resource inResources:self.resources];
    if (resourceIndex != NSNotFound) {
        if (shouldPutNameInTitle) {
            //self.title = resource.title;
        } else {
            self.title = [NSString stringWithFormat:@"%@ (%ld of %lu)",resource.room, (long)resourceIndex + 1, (unsigned long)self.resources.count];
        }
        [self.navigationItem setRightBarButtonItems:self.mainLoopCycleButtons animated:YES];
    }
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITMobiusResource *currentResource = [self resourceForViewController:viewController];
    NSInteger index = [self indexOfResource:currentResource inResources:self.resources];
    
    if (index != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:index];
        MITMobiusResource *prevResource = [self.resources objectAtIndex:prevIndex];
        return [self detailViewControllerForResource:prevResource];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITMobiusResource *currentResource = [self resourceForViewController:viewController];
    NSInteger index = [self indexOfResource:currentResource inResources:self.resources];

    if (index != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:index];
        MITMobiusResource *nextResource = [self.resources objectAtIndex:nextIndex];
        return [self detailViewControllerForResource:nextResource];
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
        MITMobiusResource *newResource = [self resourceForViewController:currentViewController];
        [self configureForResource:newResource];
    }
    self.isTransitioning = NO;
}

#pragma mark - Detail View Controllers

- (MITMobiusResource *)resourceForViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITMobiusDetailTableViewController class]]) {
        return ((MITMobiusDetailTableViewController *)viewController).resource;
    }
    return nil;
}

- (MITMobiusDetailTableViewController *)detailViewControllerForResource:(MITMobiusResource *)resource
{
//TODO change to initWithResource
    MITMobiusDetailTableViewController *detailViewController = [[MITMobiusDetailTableViewController alloc] init];
    detailViewController.resource = resource;
    return detailViewController;
}

#pragma mark - Cycling Between Resources

- (void)displayNextResource
{
    NSInteger currentIndex = [self indexOfResource:self.currentResource inResources:self.resources];
    
    if (currentIndex != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:currentIndex];
        MITMobiusResource *nextResource = [self.resources objectAtIndex:nextIndex];
        [self transitionToResource:nextResource];
    }
}

- (void)displayPreviousResource
{
    NSInteger currentIndex = [self indexOfResource:self.currentResource inResources:self.resources];

    if (currentIndex != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:currentIndex];
        MITMobiusResource *prevResource = [self.resources objectAtIndex:prevIndex];
        [self transitionToResource:prevResource];
    }
}

- (void)transitionToResource:(MITMobiusResource *)resource
{
    if (self.isTransitioning) {
        return;
    }
    self.isTransitioning = YES;
    
    NSInteger currentIndex = [self indexOfResource:self.currentResource inResources:self.resources];
    NSInteger newIndex = [self indexOfResource:resource inResources:self.resources];

    
    // If the new resource is immediately before or after the current one in main loop order, then
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
    
    MITMobiusDetailTableViewController *detailViewController = [self detailViewControllerForResource:resource];
    __weak MITMobiusDetailContainerViewController *weakSelf = self;
    [self.pageViewController setViewControllers:@[detailViewController] direction:direction animated:animated completion:^(BOOL finished) {
        // Programmatic transitions do not trigger the delegate methods, so we need to manually reconfigure for the new resource after we are done.
        [weakSelf configureForResource:resource];
        weakSelf.isTransitioning = NO;
    }];
}

#pragma mark - Main Loop Index Math

- (NSInteger)indexAfterIndex:(NSInteger)index
{
    return (index + 1) % self.resources.count;
}

- (NSInteger)indexBeforeIndex:(NSInteger)index
{
    return (index + self.resources.count - 1 ) % self.resources.count;
}

- (NSInteger)indexOfResource:(MITMobiusResource *)resource inResources:(NSArray *)resources
{
    __block NSInteger index = NSNotFound;
    
    [resources enumerateObjectsUsingBlock:^(MITMobiusResource *obj, NSUInteger idx, BOOL *stop) {
        if([obj.identifier isEqualToString:resource.identifier]) {
            index = idx;
            (*stop) = YES;
        }
    }];
    return index;
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
