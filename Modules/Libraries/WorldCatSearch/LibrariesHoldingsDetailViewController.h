#import <UIKit/UIKit.h>

@interface LibrariesHoldingsDetailViewController : UITableViewController
@property (nonatomic,copy) NSArray *holdings;

- (id)initWithHoldings:(NSArray*)holdings;
@end
