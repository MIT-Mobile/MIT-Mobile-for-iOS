#import <UIKit/UIKit.h>
#import "MITTabView.h"

@interface LibrariesAccountViewController : UIViewController <MITTabViewDelegate>
@property (nonatomic,readonly) id activeTabController;

- (void)reportError:(NSError*)error fromTab:(id)tabController;
@end
