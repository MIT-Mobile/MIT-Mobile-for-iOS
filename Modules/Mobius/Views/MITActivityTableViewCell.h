#import <UIKit/UIKit.h>
#import "MITLoadingActivityView.h"

@interface MITActivityTableViewCell : UITableViewCell
@property (nonatomic,weak) IBOutlet MITLoadingActivityView *activityView;

- (instancetype)initWithReuseIdentifier:(NSString*)reuseIdentifier;
@end
