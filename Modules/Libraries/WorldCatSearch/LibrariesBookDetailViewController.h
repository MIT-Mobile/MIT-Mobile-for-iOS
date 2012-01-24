#import <UIKit/UIKit.h>
#import "WorldCatBook.h"
#import "MITLoadingActivityView.h"
#import <MessageUI/MessageUI.h>

typedef enum {
    BookLoadingStatusPartial,
    BookLoadingStatusFailed,
    BookLoadingStatusCompleted
} BookLoadingStatus;

@interface LibrariesBookDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate> {
}

@property (nonatomic, retain) UIView *activityView;
@property (nonatomic, retain) WorldCatBook *book;
@property (nonatomic, assign) BookLoadingStatus loadingStatus;
@property (nonatomic, retain) NSArray *bookInfo;

@end

