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

@class MITCalendarsEvent, MITEventDetailViewController;

@protocol MITEventDetailViewControllerDelegate <NSObject>

@optional
- (void)eventDetailViewControllerDidUpdateSize:(MITEventDetailViewController *)eventDetailViewController;

@end

@interface MITEventDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITCalendarsEvent *event;

@property (weak, nonatomic) id<MITEventDetailViewControllerDelegate> delegate;

/*!
 The height that the tableView will be when fully loaded.  Used to predict height before loading into view.
 */
- (CGFloat)targetTableViewHeight;

@end
