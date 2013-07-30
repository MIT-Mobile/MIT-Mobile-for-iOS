#import <UIKit/UIKit.h>
#import "WorldCatBook.h"
#import "MITLoadingActivityView.h"
#import <MessageUI/MessageUI.h>

@interface LibrariesBookDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate>
@property (nonatomic,weak) UIView *activityView;
@property (strong) WorldCatBook *book;
@property (copy) NSArray *bookInfo;

@end

