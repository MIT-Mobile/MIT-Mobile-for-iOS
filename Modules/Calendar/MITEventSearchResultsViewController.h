#import <UIKit/UIKit.h>

@class MITCalendarsEvent;
@class MITCalendarsCalendar;
@protocol MITEventSearchResultsViewControllerDelegate;

@interface MITEventSearchResultsViewController : UIViewController

@property (nonatomic, weak) id<MITEventSearchResultsViewControllerDelegate> delegate;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;

- (void)beginSearch:(NSString *)searchString;
@end

@protocol MITEventSearchResultsViewControllerDelegate <NSObject>

- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didLoadResults:(NSArray *)results;
- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didSelectEvent:(MITCalendarsEvent *)event;

@end