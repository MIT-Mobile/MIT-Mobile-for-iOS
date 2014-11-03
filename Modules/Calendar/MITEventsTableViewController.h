#import <UIKit/UIKit.h>

@class MITEventsTableViewController, MITCalendarsEvent;

@protocol  MITEventsTableViewControllerDelegate <NSObject>

- (void)eventsTableView:(MITEventsTableViewController *)tableView
         didSelectEvent:(MITCalendarsEvent *)event;

@end

@interface MITEventsTableViewController : UIViewController

@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<MITEventsTableViewControllerDelegate> delegate;
@property (nonatomic) BOOL shouldIncludeNumberedPrefixes;
@property (nonatomic) CGFloat tableViewTopInset;
@end
