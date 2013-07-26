#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FacilitiesRootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,MFMailComposeViewControllerDelegate>
@property (nonatomic,strong) IBOutlet UITextView *textView;
@property (nonatomic,strong) IBOutlet UITableView* tableView;

@end
