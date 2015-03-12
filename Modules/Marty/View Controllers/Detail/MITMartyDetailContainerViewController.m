#import "MITMartyDetailContainerViewController.h"
#import "MITMartyDetailTableViewController.h"

@interface MITMartyDetailContainerViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSArray *resources;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *mainLoopCycleButtons;

@property (strong, nonatomic) MITMartyResource *currentResource;

@property (nonatomic) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *inputViews;

@end

@implementation MITMartyDetailContainerViewController

- (instancetype)initWithResource:(MITMartyResource *)resource resources:(NSArray *)resources nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.currentResource = resource;
        self.resources = resources;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupToolbar];
    [self createPageViewController];
    [self setupMainLoopCycleButtons];
    [self configureForResource:self.currentResource];
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

- (void)configureForResource:(MITMartyResource *)resource
{
    self.currentResource = resource;
    [self configureNavigationForResource:resource shouldPutNameInTitle:NO];
}

- (void)configureNavigationForResource:(MITMartyResource *)resource shouldPutNameInTitle:(BOOL)shouldPutNameInTitle
{
    NSInteger resourceIndex = [self indexOfResource:resource inResources:self.resources];
    if (resourceIndex != NSNotFound) {
        if (shouldPutNameInTitle) {
            self.title = resource.title;
        } else {
            self.title = [NSString stringWithFormat:@"Main Loop %ld of %lu", (long)resourceIndex + 1, (unsigned long)self.resources.count];
        }
        [self.navigationItem setRightBarButtonItems:self.mainLoopCycleButtons animated:YES];
    } else {
        if (shouldPutNameInTitle) {
            self.title = [NSString stringWithFormat:@"Side Trip - %@", resource.title];
        } else {
            self.title = @"Side Trip";
        }
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
    }
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITMartyResource *currentResource = [self resourceForViewController:viewController];
    NSInteger index = [self indexOfResource:currentResource inResources:self.resources];
    
    if (index != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:index];
        MITMartyResource *prevResource = [self.resources objectAtIndex:prevIndex];
        return [self detailViewControllerForResource:prevResource];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITMartyResource *currentResource = [self resourceForViewController:viewController];
    NSInteger index = [self indexOfResource:currentResource inResources:self.resources];

    if (index != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:index];
        MITMartyResource *nextResource = [self.resources objectAtIndex:nextIndex];
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
        MITMartyResource *newResource = [self resourceForViewController:currentViewController];
        [self configureForResource:newResource];
    }
    self.isTransitioning = NO;
}

#pragma mark - Detail View Controllers

- (MITMartyResource *)resourceForViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITMartyDetailTableViewController class]]) {
        return ((MITMartyDetailTableViewController *)viewController).resource;
    }
    return nil;
}

- (MITMartyDetailTableViewController *)detailViewControllerForResource:(MITMartyResource *)resource
{
//TODO change to initWithResource
    MITMartyDetailTableViewController *detailViewController = [[MITMartyDetailTableViewController alloc] init];
    detailViewController.resource = resource;
    return detailViewController;
}

#pragma mark - Cycling Between Resources

- (void)displayNextResource
{
    NSInteger currentIndex = [self indexOfResource:self.currentResource inResources:self.resources];
    
    if (currentIndex != NSNotFound) {
        NSInteger nextIndex = [self indexAfterIndex:currentIndex];
        MITMartyResource *nextResource = [self.resources objectAtIndex:nextIndex];
        [self transitionToResource:nextResource];
    }
}

- (void)displayPreviousResource
{
    NSInteger currentIndex = [self indexOfResource:self.currentResource inResources:self.resources];

    if (currentIndex != NSNotFound) {
        NSInteger prevIndex = [self indexBeforeIndex:currentIndex];
        MITMartyResource *prevResource = [self.resources objectAtIndex:prevIndex];
        [self transitionToResource:prevResource];
    }
}

- (void)transitionToResource:(MITMartyResource *)resource
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
    
    MITMartyDetailTableViewController *detailViewController = [self detailViewControllerForResource:resource];
    __weak MITMartyDetailContainerViewController *weakSelf = self;
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

- (NSInteger)indexOfResource:(MITMartyResource *)resource inResources:(NSArray *)resources
{
    __block NSInteger index = NSNotFound;
    
    [resources enumerateObjectsUsingBlock:^(MITMartyResource *obj, NSUInteger idx, BOOL *stop) {
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
