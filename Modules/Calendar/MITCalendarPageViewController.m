#import "MITCalendarPageViewController.h"
#import "MITEventsTableViewController.h"
#import "Foundation+MITAdditions.h"
#import "MITCalendarWebservices.h"

@interface MITCalendarPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, MITEventsTableViewControllerDelegate>

@end

@implementation MITCalendarPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    self.dataSource = self;
    [self setViewControllers:@[[[MITEventsTableViewController alloc] init]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
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
    eventsTableViewController.shouldIndicateCellSelectedState = self.shouldIndicateCellSelectedState;
    
    if (self.calendar) {
        [MITCalendarWebservices getEventsForCalendar:self.calendar category:self.category date:eventsTableViewController.date completion:^(NSArray *events, NSError *error)  {
            if (events) {
                [eventsTableViewController setEvents:events];
                if (eventsTableViewController == [self.viewControllers firstObject]) {
                    [self currentlyDisplayedEventsDidChange:events];
                    [eventsTableViewController selectFirstRow];
                }
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
        MITEventsTableViewController *currentlyDisplayedController = (MITEventsTableViewController *)self.viewControllers[0];
        if ([self.calendarSelectionDelegate respondsToSelector:@selector(calendarPageViewController:didSwipeToDate:)]) {
            self.date = currentlyDisplayedController.date;
            [self.calendarSelectionDelegate calendarPageViewController:self didSwipeToDate:[currentlyDisplayedController date]];
        }
        if (currentlyDisplayedController.events) {
            [self currentlyDisplayedEventsDidChange:currentlyDisplayedController.events];
        }
    }
}

- (void)moveToCalendar:(MITCalendarsCalendar *)calendar category:(MITCalendarsCalendar *)category date:(NSDate *)date animated:(BOOL)animated
{
    UIPageViewControllerNavigationDirection navigationDirection = UIPageViewControllerNavigationDirectionForward;
    if ([self.date compare:date] == NSOrderedDescending) {
        navigationDirection = UIPageViewControllerNavigationDirectionReverse;
    }
    self.date = date;
    self.calendar = calendar;
    self.category = category;
    
    [self setViewControllers:@[[self eventControllerForDate:self.date]] direction:navigationDirection animated:NO completion:NULL];
}

- (void)loadEvents
{
    [self setViewControllers:@[[self eventControllerForDate:self.date]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}

#pragma mark - Events Table Delegate

- (void)eventsTableView:(MITEventsTableViewController *)tableView didSelectEvent:(MITCalendarsEvent *)event
{
    if ([self.calendarSelectionDelegate respondsToSelector:@selector(calendarPageViewController:didSelectEvent:)]) {
        [self.calendarSelectionDelegate calendarPageViewController:self didSelectEvent:event];
    }
}

#pragma mark - Notify Updated Events

- (void)currentlyDisplayedEventsDidChange:(NSArray *)currentlyDisplayedEvents
{
    if ([self.calendarSelectionDelegate respondsToSelector:@selector(calendarPageViewController:didUpdateCurrentlyDisplayedEvents:)]) {
        [self.calendarSelectionDelegate calendarPageViewController:self didUpdateCurrentlyDisplayedEvents:currentlyDisplayedEvents];
    }
}

@end
