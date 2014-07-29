#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITEventDetailRowType) {
    MITEventDetailRowTypeTime,
    MITEventDetailRowTypeLocation,
    MITEventDetailRowTypePhone,
    MITEventDetailRowTypeWebsite,
    MITEventDetailRowTypeDescription
};

@class MITCalendarEvent;

@interface MITEventDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITCalendarEvent *event;

@end
