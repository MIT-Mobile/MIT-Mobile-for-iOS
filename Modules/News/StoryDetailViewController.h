#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"

@class NewsStory;
@class StoryListViewController;

@interface StoryDetailViewController : ShareDetailViewController <UIWebViewDelegate, ShareItemDelegate> {
	StoryListViewController *newsController;
    NewsStory *story;
	
	UISegmentedControl *storyPager;
    
    UIWebView *storyView;
}

@property (nonatomic, retain) StoryListViewController *newsController;
@property (nonatomic, retain) NewsStory *story;
@property (nonatomic, retain) UIWebView *storyView;

- (void)displayStory:(NewsStory *)aStory;

@end
