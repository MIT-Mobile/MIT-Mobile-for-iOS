#import "MITShuttleStopPopoverViewController.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStopPredictionLoader.h"

@interface MITShuttleStopPopoverViewController () <UIScrollViewDelegate, MITShuttleStopPredictionLoaderDelegate>

@property (weak, nonatomic) IBOutlet UILabel *stopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *routeNameLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) MITShuttleStopPredictionLoader *predictionLoader;
@property (nonatomic, strong) NSArray *orderedRoutes;
@property (nonatomic, strong) NSArray *stopViewControllers;

@end

@implementation MITShuttleStopPopoverViewController

#pragma mark - Init

- (instancetype)initWithStop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _stop = stop;
        _currentRoute = route;
        [self setupPredictionLoader];
        [self setupStopViewControllers];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.stopNameLabel.text = self.stop.name;
    [self configureViewForRoute:self.currentRoute];
    [self layoutStopViews];
    [self setupPageControl];
    self.contentSizeForViewInPopover = self.view.frame.size;
    [self.predictionLoader startRefreshingPredictions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupPredictionLoader
{
    MITShuttleStopPredictionLoader *predictionLoader = [[MITShuttleStopPredictionLoader alloc] initWithStop:self.stop];
    predictionLoader.delegate = self;
    self.predictionLoader = predictionLoader;
}

- (void)setupStopViewControllers
{
    NSMutableOrderedSet *routes = [self.stop.routes mutableCopy];
    if (self.currentRoute) {
        [routes removeObject:self.currentRoute];
        [routes insertObject:self.currentRoute atIndex:0];
    }
    self.orderedRoutes = [routes array];
    NSMutableArray *stopViewControllers = [NSMutableArray arrayWithCapacity:[routes count]];
    for (MITShuttleRoute *route in routes) {
        MITShuttleStopViewController *stopViewController = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                                          stop:self.stop
                                                                                                         route:route
                                                                                              predictionLoader:self.predictionLoader];
        stopViewController.viewOption = MITShuttleStopViewOptionAll;
        [stopViewControllers addObject:stopViewController];
    }
    self.stopViewControllers = [NSArray arrayWithArray:stopViewControllers];
}

- (void)setupPageControl
{
    self.pageControl.transform = CGAffineTransformMakeScale(2.0, 2.0);
    self.pageControl.numberOfPages = [self.stop.routes count];
}

- (void)configureViewForRoute:(MITShuttleRoute *)route
{
    self.routeNameLabel.text = route.title;
}

#pragma mark - Layout

- (void)layoutStopViews
{
    CGFloat width = self.scrollView.frame.size.width;
    CGFloat height = self.scrollView.frame.size.height;
    NSInteger index = 0;
    for (MITShuttleStopViewController *viewController in self.stopViewControllers) {
        [self addChildStopViewController:viewController];
        
        UIView *view = viewController.view;
        view.frame = CGRectMake(width * index, 0, width, height);
        ++index;
    }
    self.scrollView.contentSize = CGSizeMake(index * width, height);
}

- (void)addChildStopViewController:(MITShuttleStopViewController *)stopViewController
{
    [self addChildViewController:stopViewController];
    [self.scrollView addSubview:stopViewController.view];
    [stopViewController didMoveToParentViewController:self];
}

#pragma mark - Actions

- (IBAction)routeViewTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(stopPopoverViewController:didSelectRoute:)]) {
        [self.delegate stopPopoverViewController:self didSelectRoute:self.currentRoute];
    }
}

- (IBAction)pageControlValueChanged:(id)sender
{
    NSInteger currentPage = self.pageControl.currentPage;
    [self.scrollView setContentOffset:CGPointMake(currentPage * self.scrollView.frame.size.width, 0) animated:YES];
}

- (void)didScrollToRoute:(MITShuttleRoute *)route
{
    [self configureViewForRoute:route];
    self.currentRoute = route;
    if ([self.delegate respondsToSelector:@selector(stopPopoverViewController:didScrollToRoute:)]) {
        [self.delegate stopPopoverViewController:self didScrollToRoute:route];
    }
}

#pragma mark - MITShuttleStopPredictionLoaderDelegate

- (void)stopPredictionLoaderWillReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    for (MITShuttleStopViewController *viewController in self.stopViewControllers) {
        [viewController beginRefreshing];
    }
}

- (void)stopPredictionLoaderDidReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    for (MITShuttleStopViewController *viewController in self.stopViewControllers) {
        [viewController endRefreshing];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollingDidEnd];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollingDidEnd];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollingDidEnd];
}

- (void)scrollingDidEnd
{
    NSInteger routeIndex = self.scrollView.contentOffset.x / self.scrollView.frame.size.width;
    MITShuttleRoute *route = self.orderedRoutes[routeIndex];
    self.pageControl.currentPage = routeIndex;
    [self didScrollToRoute:route];
}

@end
