#import "MITMobiusDetailContainerViewController.h"
#import "MITMobiusDetailTableViewController.h"

@interface MITMobiusDetailContainerViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

@property (nonatomic) NSUInteger currentIndex;

@property (nonatomic,getter=isTransitioning) BOOL transitioning;
@property (nonatomic, strong) NSMutableArray *inputViews;
@property (nonatomic,getter=isPagingEnabled) BOOL pagingEnabled;

@property (nonatomic,weak) UIBarButtonItem *pagingBarButtonItem;
@property (nonatomic,weak) UIButton *nextPageButton;
@property (nonatomic,weak) UIButton *previousPageButton;

@end

@implementation MITMobiusDetailContainerViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        _currentIndex = NSNotFound;
        _pagingEnabled = YES;
    }

    return self;
}

- (instancetype)initWithResource:(MITMobiusResource *)resource
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _currentResource = resource;
        _currentIndex = NSNotFound;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createPageViewController];
    [self setupMainLoopCycleButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.currentIndex != NSNotFound) {
        self.currentResource = [self resourceAtIndex:self.currentIndex];
    }
    
    [self configureForResource:self.currentResource animated:animated];
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

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.pageViewController.automaticallyAdjustsScrollViewInsets = YES;
    self.pageViewController.edgesForExtendedLayout = UIRectEdgeAll;
    
    UIView *pageView = self.pageViewController.view;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:pageView];
    [self.pageViewController didMoveToParentViewController:self];
    
    UIViewController *currentPage = [self detailViewControllerForResource:self.currentResource];
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

    self.pagingBarButtonItem = buttonContainerItem;
    self.nextPageButton = upButton;
    self.previousPageButton = downButton;
}

- (void)_updatePagingButtonState:(BOOL)animated
{
    NSTimeInterval duration = (animated ? 0.33 : 0.);
    if (self.isPagingEnabled) {
        NSUInteger nextIndex = [self indexAfterIndex:self.currentIndex];
        NSUInteger previousIndex = [self indexBeforeIndex:self.currentIndex];

        [UIView animateWithDuration:duration animations:^{
            self.nextPageButton.alpha = 1.;
            self.previousPageButton.alpha = 1.;
            self.pagingBarButtonItem.enabled = YES;

            if (nextIndex == NSNotFound) {
                self.nextPageButton.enabled = NO;
            } else {
                self.nextPageButton.enabled = YES;
            }

            if (previousIndex == NSNotFound) {
                self.previousPageButton.enabled = NO;
            } else {
                self.previousPageButton.enabled = YES;
            }
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            self.nextPageButton.alpha = 0;
            self.previousPageButton.alpha = 0;
            self.pagingBarButtonItem.enabled = NO;
        }];
    }
}

#pragma mark - Transition

- (NSMutableArray *)inputViews {
    if (_inputViews == nil) {
        _inputViews = [[NSMutableArray alloc] init];
    }
    return _inputViews;
}

- (void)setTransitioning:(BOOL)transitioning {
    if (_transitioning != transitioning) {
        _transitioning = transitioning;

        for (UIView *view in self.inputViews) {
            view.userInteractionEnabled = !transitioning;
        }
    }
}

#pragma mark Properties
- (BOOL)isPagingEnabled
{
    return (_pagingEnabled && (self.delegate != nil) && ([self numberOfResources] > 1));
}

#pragma mark - Configuration for Resource

- (void)configureForResource:(MITMobiusResource *)resource animated:(BOOL)animated
{
    self.currentIndex = [self indexForResource:resource];
    
    [self configureNavigationForResource:resource animated:animated];
}

- (void)configureNavigationForResource:(MITMobiusResource*)resource animated:(BOOL)animated
{
    NSParameterAssert(resource);

    if (!self.isPagingEnabled) {
        self.title = nil;
    } else {
        NSUInteger index = [self indexForResource:resource] + 1; // Increment by 1 to make the display value 1-indexed
        NSUInteger numberOfResources = [self numberOfResources];
        self.title = [NSString stringWithFormat:@"%@ (%lu of %lu)",resource.room, (unsigned long)index, (unsigned long)numberOfResources];
    }

    [self.navigationItem setRightBarButtonItems:self.mainLoopCycleButtons animated:animated];
    [self _updatePagingButtonState:animated];
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITMobiusResource *currentResource = [self resourceForViewController:viewController];
    NSUInteger resourceIndex = [self indexForResource:currentResource];

    if (resourceIndex != NSNotFound) {
        NSUInteger previousIndex = [self indexBeforeIndex:resourceIndex];
        return [self detailViewControllerForResourceAtIndex:previousIndex];
    }

    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITMobiusResource *currentResource = [self resourceForViewController:viewController];
    NSUInteger resourceIndex = [self indexForResource:currentResource];

    if (resourceIndex != NSNotFound) {
        NSUInteger nextIndex = [self indexAfterIndex:resourceIndex];
        return [self detailViewControllerForResourceAtIndex:nextIndex];
    }

    return nil;
}

#pragma mark - UIPageViewControllerDelegateMethods

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    self.transitioning = YES;
    
    // Persist the currently selected segment across pages (done in two places in this class)
    MITMobiusDetailTableViewController *tableViewController = (MITMobiusDetailTableViewController *)pageViewController.viewControllers[0];
    NSInteger currentSegmentedSection = tableViewController.currentSegmentedSection;
    [pendingViewControllers enumerateObjectsUsingBlock:^(MITMobiusDetailTableViewController *obj, NSUInteger idx, BOOL *stop) {
        obj.currentSegmentedSection = currentSegmentedSection;
    }];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        UIViewController *currentViewController = self.pageViewController.viewControllers[0];
        MITMobiusResource *newResource = [self resourceForViewController:currentViewController];
        [self configureForResource:newResource animated:NO];
    }

    self.transitioning = NO;
}

#pragma mark - Detail View Controllers

- (MITMobiusResource *)resourceForViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITMobiusDetailTableViewController class]]) {
        return ((MITMobiusDetailTableViewController *)viewController).resource;
    }
    return nil;
}

- (MITMobiusDetailTableViewController *)detailViewControllerForResourceAtIndex:(NSUInteger)index
{
    if (index == NSNotFound) {
        return nil;
    } else {
        MITMobiusResource *resource = [self resourceAtIndex:index];
        return [self detailViewControllerForResource:resource];
    }
}

- (MITMobiusDetailTableViewController *)detailViewControllerForResource:(MITMobiusResource *)resource
{
    MITMobiusDetailTableViewController *detailViewController = [[MITMobiusDetailTableViewController alloc] initWithResource:resource];
    return detailViewController;
}

#pragma mark - Cycling Between Resources

- (void)displayNextResource
{
    NSUInteger nextIndex = [self indexAfterIndex:self.currentIndex];
    [self transitionToResourceAtIndex:nextIndex];
}

- (void)displayPreviousResource
{
    NSUInteger previousIndex = [self indexBeforeIndex:self.currentIndex];
    [self transitionToResourceAtIndex:previousIndex];
}

- (void)transitionToResourceAtIndex:(NSUInteger)index
{
    if (index == NSNotFound) {
        return;
    }

    MITMobiusResource *resource = [self resourceAtIndex:index];
    if (resource) {
        [self transitionFromResourceAtIndex:self.currentIndex toIndex:index animated:YES];
    }
}

- (void)transitionFromResourceAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex animated:(BOOL)animated
{
    if (self.isTransitioning) {
        return;
    }

    self.transitioning = YES;

    // If the new resource is immediately before or after the current one in main loop order, then
    // we want the transition to be animated as if the user had swiped.
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;

    if (oldIndex != NSNotFound && newIndex != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:oldIndex];
        NSInteger prevIndex = [self indexBeforeIndex:oldIndex];
        if ((newIndex != nextIndex) && (newIndex != prevIndex)) {
            animated = NO;
        } else if (newIndex == prevIndex) {
            direction = UIPageViewControllerNavigationDirectionReverse;
        }
    }

    MITMobiusResource *resource = [self resourceAtIndex:newIndex];
    MITMobiusDetailTableViewController *detailViewController = [self detailViewControllerForResource:resource];

    // Persist the currently selected segment across pages (done in two places in this class)
    NSInteger currentSegmentedSection = ((MITMobiusDetailTableViewController *)self.pageViewController.viewControllers[0]).currentSegmentedSection;
    detailViewController.currentSegmentedSection = currentSegmentedSection;

    if (detailViewController) {

        __weak MITMobiusDetailContainerViewController *weakSelf = self;
        [self.pageViewController setViewControllers:@[detailViewController] direction:direction animated:animated completion:^(BOOL finished) {
            // Programmatic transitions do not trigger the delegate methods, so we need to manually reconfigure for the new resource after we are done.
            [weakSelf configureForResource:resource animated:animated];
            weakSelf.transitioning = NO;
        }];
    }
}

#pragma mark - Main Loop Index Math
- (NSUInteger)numberOfResources
{
    return [self.delegate numberOfResourcesInDetailViewController:self];
}

- (MITMobiusResource*)resourceAtIndex:(NSUInteger)index
{
    if (index == NSNotFound) {
        return self.currentResource;
    } else {
        return [self.delegate detailViewController:self resourceAtIndex:index];
    }

}

- (NSUInteger)indexForResource:(MITMobiusResource*)resource
{
    if (resource) {
        return [self.delegate detailViewController:self indexForResourceWithIdentifier:resource.identifier];
    } else {
        return NSNotFound;
    }
}

- (NSUInteger)indexAfterIndex:(NSUInteger)index
{
    if (self.delegate) {
        return [self.delegate detailViewController:self indexAfterIndex:index];
    } else {
        return NSNotFound;
    }
}

- (NSInteger)indexBeforeIndex:(NSInteger)index
{
    if (self.delegate) {
        return [self.delegate detailViewController:self indexBeforeIndex:index];
    } else {
        return NSNotFound;
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
