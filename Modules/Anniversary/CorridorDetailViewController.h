#import <UIKit/UIKit.h>

@class CorridorStory;

@interface CorridorDetailViewController : UIViewController <UIWebViewDelegate> {
	CorridorStory *story;
	
	UIWebView *webView;
}

@property (nonatomic, retain) CorridorStory *story;
@property (nonatomic, retain) UIWebView *webView;

- (void)displayStory;

@end
