#import <UIKit/UIKit.h>

@protocol EmergencyViewControllerDelegate<NSObject>
@optional
- (void)didReadNewestEmergencyInfo;
@end


@interface EmergencyViewController : UITableViewController <UIWebViewDelegate>
@property (weak) id<EmergencyViewControllerDelegate> delegate;

- (void)refreshInfo;

@end
