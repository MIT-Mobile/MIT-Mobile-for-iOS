#import "MITShuttleStopPopoverViewController.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"

@interface MITShuttleStopPopoverViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *stopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *routeNameLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

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
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupStopViewControllers
{
    NSMutableOrderedSet *routes = [self.stop.routes mutableCopy];
    if (self.currentRoute) {
        [routes insertObject:self.currentRoute atIndex:0];
    }
    self.orderedRoutes = [routes array];
    NSMutableArray *stopViewControllers = [NSMutableArray arrayWithCapacity:[routes count]];
    for (MITShuttleRoute *route in routes) {
        [stopViewControllers addObject:[[MITShuttleStopViewController alloc] initWithStop:self.stop]];
    }
    self.stopViewControllers = [NSArray arrayWithArray:stopViewControllers];
}

- (void)configureViewForRoute:(MITShuttleRoute *)route
{
    self.routeNameLabel.text = route.title;
}

#pragma mark - Layout

- (void)layoutStopViews
{
    CGFloat width = self.scrollView.frame.size.width;
    NSInteger index = 0;
    for (MITShuttleStopViewController *viewController in self.stopViewControllers) {
        UIView *view = viewController.view;
        view.frame = CGRectMake(width * index, 0, width, self.scrollView.frame.size.height);
        ++index;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger stopIndex = (*targetContentOffset).x / scrollView.frame.size.width;
    MITShuttleRoute *route = self.stop.routes[stopIndex];
    [self configureViewForRoute:route];
}

@end
