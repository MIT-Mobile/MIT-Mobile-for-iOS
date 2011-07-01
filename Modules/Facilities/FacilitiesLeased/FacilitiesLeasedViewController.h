#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class FacilitiesLocation;

@interface FacilitiesLeasedViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate> {
    FacilitiesLocation *_location;
    UITableView *_contactsTable;
    UITextView *_messageView;
}

@property (nonatomic, retain) UITableView* contactsTable;
@property (nonatomic, retain) UITextView* messageView;
@property (nonatomic, readonly, retain) FacilitiesLocation* location;

- (id)initWithLocation:(FacilitiesLocation*)location;
@end
