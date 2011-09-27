#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FacilitiesRootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,MFMailComposeViewControllerDelegate> {
    UITextView *_textView;
    UITableView *_tableView;
}

@property (nonatomic,readonly,retain) IBOutlet UITextView *textView;
@property (nonatomic,readonly,retain) IBOutlet UITableView* tableView;

@end
