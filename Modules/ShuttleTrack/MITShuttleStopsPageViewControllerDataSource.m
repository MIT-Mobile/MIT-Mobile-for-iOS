#import "MITShuttleStopsPageViewControllerDataSource.h"
#import "MITShuttleStopViewController.h"
#import "MITShuttleStop.h"

@implementation MITShuttleStopsPageViewControllerDataSource

- (UIViewController *)viewControllerForStop:(MITShuttleStop *)stop
{
    MITShuttleStopViewController *stopVc = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped stop:stop route:stop.route];
    return stopVc;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITShuttleStopViewController *currentVc = (MITShuttleStopViewController *)viewController;
    MITShuttleStop *currentStop = currentVc.stop;
    
    NSUInteger indexOfCurrentStop = [self.stops indexOfObject:currentStop];
    MITShuttleStop *previousStop;
    
    if (indexOfCurrentStop > 0) {
        previousStop = self.stops[indexOfCurrentStop - 1];
    } else if (indexOfCurrentStop == 0) {
        previousStop = [self.stops lastObject];
    } else {
        // NSNotFound
        return nil;
    }
    
    MITShuttleStopViewController *previousVc = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped stop:previousStop route:previousStop.route];
    return previousVc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITShuttleStopViewController *currentVc = (MITShuttleStopViewController *)viewController;
    MITShuttleStop *currentStop = currentVc.stop;
    
    NSUInteger indexOfCurrentStop = [self.stops indexOfObject:currentStop];
    MITShuttleStop *nextStop;
    
    if (indexOfCurrentStop < self.stops.count - 1) {
        nextStop = self.stops[indexOfCurrentStop + 1];
    } else if (indexOfCurrentStop == self.stops.count - 1) {
        nextStop = [self.stops firstObject];
    } else {
        // NSNotFound
        return nil;
    }
    
    MITShuttleStopViewController *nextVc = [[MITShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped stop:nextStop route:nextStop.route];
    return nextVc;
}

@end
