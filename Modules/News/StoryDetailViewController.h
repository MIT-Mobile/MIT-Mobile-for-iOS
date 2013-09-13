#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ShareDetailViewController.h"

@class NewsStory;
@class StoryListViewController;
@protocol StoryDetailPagingDelegate;

@interface StoryDetailViewController : ShareDetailViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, ShareItemDelegate>
@property (nonatomic,weak) id<StoryDetailPagingDelegate> pagingDelegate;
@property (strong) NewsStory *story;

- (void)displayStory:(NewsStory *)aStory;

@end

@protocol StoryDetailPagingDelegate <NSObject>
- (BOOL)storyDetailView:(StoryDetailViewController*)storyDetailController canSelectPreviousStory:(NewsStory*)currentStory;
- (NewsStory*)storyDetailView:(StoryDetailViewController*)storyDetailController selectPreviousStory:(NewsStory*)currentStory;
- (BOOL)storyDetailView:(StoryDetailViewController*)storyDetailController canSelectNextStory:(NewsStory*)currentStory;
- (NewsStory*)storyDetailView:(StoryDetailViewController*)storyDetailController selectNextStory:(NewsStory*)currentStory;
@end