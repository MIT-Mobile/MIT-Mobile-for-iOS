#import <Foundation/Foundation.h>

@class MITShuttleStop;

@interface MITShuttleStopsPageViewControllerDataSource : NSObject <UIPageViewControllerDataSource>

@property (nonatomic, strong) NSArray *stops;


- (UIViewController *)viewControllerForStop:(MITShuttleStop *)stop;

@end
