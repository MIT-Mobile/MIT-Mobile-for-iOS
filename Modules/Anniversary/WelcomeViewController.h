#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MITMobileWebAPI.h"

@class MPMoviePlayerController;

@interface WelcomeViewController : UIViewController <UIWebViewDelegate, JSONLoadedDelegate> {
	UIWebView *webView;
	
    BOOL playingVideo;
    MPMoviePlayerController *moviePlayer;
}

@property (nonatomic, retain) UIWebView *webView;

- (void)playVideo;
- (void)videoDidFinish:(NSNotification *)notification;

@end
