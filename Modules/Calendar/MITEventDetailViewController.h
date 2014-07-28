#import <UIKit/UIKit.h>

@class MITCalendarEvent;

@interface MITEventDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITCalendarEvent *event;

@end
