#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutTableViewController : UITableViewController <MFMailComposeViewControllerDelegate> {
    BOOL showBuildNumber;
}

@end
