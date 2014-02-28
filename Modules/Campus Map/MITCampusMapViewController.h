#import <UIKit/UIKit.h>

@interface MITCampusMapViewController : UIViewController
// Set a pending search. The search will actually be
// performed in the next viewDidAppear: call
- (void)setPendingSearch:(NSString*)pendingSearch;
@end
