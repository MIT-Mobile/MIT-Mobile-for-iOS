#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ShareDetailViewController.h"

@class NewsStory;
@class StoryListViewController;

@interface StoryDetailViewController : ShareDetailViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, ShareItemDelegate>
@property (nonatomic,weak) StoryListViewController *newsController;
@property (strong) NewsStory *story;

- (void)displayStory:(NewsStory *)aStory;

@end
