#import <UIKit/UIKit.h>

@class MITLoadingActivityView;

@interface ThankYouViewController : UITableViewController
@property (nonatomic,copy) NSString *message;

- (id)initWithMessage:(NSString *)message;

@end
