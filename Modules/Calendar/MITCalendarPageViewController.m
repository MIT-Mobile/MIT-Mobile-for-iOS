#import "MITCalendarPageViewController.h"
#import "MITEventsTableViewController.h"
#import "Foundation+MITAdditions.h"
#import "MITCalendarManager.h"

@interface MITCalendarPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, MITEventsTableViewControllerDeleage>

@end

@implementation MITCalendarPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    self.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Page View Datasource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSDate *date = [(MITEventsTableViewController *)viewController date];
    return [self eventControllerForDate:[date dayAfter]];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSDate *date = [(MITEventsTableViewController *)viewController date];
    return [self eventControllerForDate:[date dayBefore]];
}

- (MITEventsTableViewController *)eventControllerForDate:(NSDate *)date
{
    MITEventsTableViewController *eventsTableViewController = [[MITEventsTableViewController alloc] init];
    eventsTableViewController.date = date;
    eventsTableViewController.delegate = self;
    
    if (self.calendar) {
        [[MITCalendarManager sharedManager] getEventsForCalendar:self.calendar
                                                        category:self.category
                                                            date:eventsTableViewController.date
                                                      completion:^(NSArray *events, NSError *error) {
                                                          if (events) {
                                                              [eventsTableViewController setEvents:events];
                                                          }
                                                      }];
    }
    return eventsTableViewController;
}

#pragma mark - Page View Delegate
- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (completed) {
        [self.calendarSelectionDelegate calendarPageViewController:self didSwipeToDate:[(MITEventsTableViewController *)self.viewControllers[0] date]];
    }
}

- (void)moveToDate:(NSDate *)date
{
    UIPageViewControllerNavigationDirection navigationDirection = UIPageViewControllerNavigationDirectionForward;
    if ([self.date compare:date] == NSOrderedDescending) {
        navigationDirection = UIPageViewControllerNavigationDirectionReverse;
    }
    [self setViewControllers:@[[self eventControllerForDate:self.date]] direction:navigationDirection animated:YES completion:NULL];
}

- (void)loadEvents
{
    [self setViewControllers:@[[self eventControllerForDate:self.date]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}

#pragma mark - Events Table Delegate

- (void)eventsTableView:(MITEventsTableViewController *)tableView didSelectEvent:(MITCalendarsEvent *)event
{
    [self.calendarSelectionDelegate calendarPageViewController:self didSelectEvent:event];
}

@end
