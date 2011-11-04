#import <UIKit/UIKit.h>

@interface LibrariesRenewViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
- (id)initWithItems:(NSArray*)renewItems;
@end
