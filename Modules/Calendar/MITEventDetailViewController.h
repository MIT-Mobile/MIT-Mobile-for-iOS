#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITEventDetailRowType) {
    MITEventDetailRowTypeSpeaker,
    MITEventDetailRowTypeTime,
    MITEventDetailRowTypeLocation,
    MITEventDetailRowTypePhone,
    MITEventDetailRowTypeDescription,
    MITEventDetailRowTypeWebsite,
    MITEventDetailRowTypeOpenTo,
    MITEventDetailRowTypeCost,
    MITEventDetailRowTypeSponsors,
    MITEventDetailRowTypeContact
};

@class MITCalendarsEvent;

@interface MITEventDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITCalendarsEvent *event;

@end
