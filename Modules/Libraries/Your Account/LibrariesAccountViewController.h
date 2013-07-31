#import <UIKit/UIKit.h>
#import "MITTabView.h"

@interface LibrariesAccountViewController : UIViewController <MITTabViewDelegate>
@property (readonly, strong) NSOperationQueue *requestOperations;
@property (nonatomic,readonly, weak) id activeTabController;

- (void)reportError:(NSError*)error fromTab:(id)tabController;
- (void)forceTabLayout;
@end