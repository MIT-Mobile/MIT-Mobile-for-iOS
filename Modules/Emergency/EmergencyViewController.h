#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@protocol EmergencyViewControllerDelegate<NSObject>

@optional
- (void)didReadNewestEmergencyInfo;

@end


@interface EmergencyViewController : UITableViewController <UIWebViewDelegate> {
    id<EmergencyViewControllerDelegate> delegate;
    
	BOOL refreshButtonPressed;
    NSString *htmlString;
	NSString *htmlFormatString;
    UIWebView *infoWebView;
}

- (void)infoDidLoad:(NSNotification *)aNotification;
- (void)infoDidFailToLoad:(NSNotification *)aNotification;

- (void)refreshInfo:(id)sender; // force view controller to refresh itself

@property (nonatomic, retain) id<EmergencyViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *htmlString;
@property (nonatomic, retain) UIWebView *infoWebView;

@end
