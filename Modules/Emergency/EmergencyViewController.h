#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"

@protocol EmergencyViewControllerDelegate<NSObject>

@optional
- (void)didReadNewestEmergencyInfo;

@end


@interface EmergencyViewController : UITableViewController <UIWebViewDelegate> {
    id<EmergencyViewControllerDelegate> delegate;
    
    NSString *htmlString;
    UIWebView *infoWebView;
}

- (void)infoDidLoad:(NSNotification *)aNotification;

@property (nonatomic, retain) id<EmergencyViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *htmlString;
@property (nonatomic, retain) UIWebView *infoWebView;

@end
