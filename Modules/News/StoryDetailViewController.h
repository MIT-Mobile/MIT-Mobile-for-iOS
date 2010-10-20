#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <MessageUI/MFMailComposeViewController.h>

@class NewsStory;

@interface StoryDetailViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, FBSessionDelegate, FBDialogDelegate> {
    
    NewsStory *story;
    
    UIWebView *storyView;
    
    FBSession *fbSession;
}

@property (nonatomic, retain) NewsStory *story;
@property (nonatomic, retain) UIWebView *storyView;

@property (nonatomic, retain) FBSession *fbSession;

@end
