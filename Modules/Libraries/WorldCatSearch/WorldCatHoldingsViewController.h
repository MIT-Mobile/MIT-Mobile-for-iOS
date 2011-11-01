#import <UIKit/UIKit.h>

@class WorldCatBook;

@interface WorldCatHoldingsViewController : UITableViewController

@property (nonatomic, retain) WorldCatBook *book;
@property (nonatomic, retain) NSArray *holdings;

@end
