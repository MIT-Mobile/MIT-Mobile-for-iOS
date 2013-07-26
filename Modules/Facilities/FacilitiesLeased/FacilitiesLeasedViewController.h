#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class FacilitiesLocation;

@interface FacilitiesLeasedViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) UITableView *contactsTable;
@property (nonatomic, strong) UILabel *messageView;
@property (nonatomic, readonly, strong) FacilitiesLocation *location;

- (id)initWithLocation:(FacilitiesLocation*)location;
@end
