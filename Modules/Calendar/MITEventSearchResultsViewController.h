#import <UIKit/UIKit.h>

@class MITCalendarsEvent;
@class MITCalendarsCalendar;
@protocol MITEventSearchResultsViewControllerDelegate;

@interface MITEventSearchResultsViewController : UIViewController

@property (nonatomic, weak) id<MITEventSearchResultsViewControllerDelegate> delegate;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
@property (nonatomic) BOOL shouldIndicateCellSelectedState;

- (void)beginSearch:(NSString *)searchString;
- (void)scrollToToday;
- (void)selectFirstRow;
@end

@protocol MITEventSearchResultsViewControllerDelegate <NSObject>

@optional
- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didLoadResults:(NSArray *)results;
- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didSelectEvent:(MITCalendarsEvent *)event;

@end