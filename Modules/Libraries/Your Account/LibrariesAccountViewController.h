#import <UIKit/UIKit.h>
#import "MITTabView.h"

@interface LibrariesAccountViewController : UIViewController <MITTabViewDelegate>
@property (nonatomic,readonly, retain) NSOperationQueue *requestOperations;
@property (nonatomic,readonly) id activeTabController;

- (void)reportError:(NSError*)error fromTab:(id)tabController;
- (void)forceTabLayout;
@end
