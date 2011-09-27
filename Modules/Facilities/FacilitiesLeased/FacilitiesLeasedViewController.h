#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class FacilitiesLocation;

@interface FacilitiesLeasedViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate> {
    FacilitiesLocation *_location;
    UITableView *_contactsTable;
    UILabel *_messageView;
}

@property (nonatomic, retain) UITableView *contactsTable;
@property (nonatomic, retain) UILabel *messageView;
@property (nonatomic, readonly, retain) FacilitiesLocation *location;

- (id)initWithLocation:(FacilitiesLocation*)location;
@end
