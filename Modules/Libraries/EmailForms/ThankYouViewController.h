#import <UIKit/UIKit.h>

@class MITLoadingActivityView;

@interface ThankYouViewController : UITableViewController {
    NSString *_message;
    MITLoadingActivityView *_loadingView;
}

- (id)initWithMessage:(NSString *)message;

@property (nonatomic, retain) NSString *message;

@end
