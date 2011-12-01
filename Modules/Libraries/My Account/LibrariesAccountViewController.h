#import <UIKit/UIKit.h>
#import "MITTabView.h"

@interface LibrariesAccountViewController : UIViewController <MITTabViewDelegate>
- (void)reportError:(NSError*)error fromTab:(id)tabController;
@end
