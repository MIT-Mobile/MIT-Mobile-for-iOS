#import <UIKit/UIKit.h>

@class WorldCatBook;

@interface WorldCatHoldingsViewController : UITableViewController
@property (nonatomic,strong) WorldCatBook *book;
@property (copy) NSArray *holdings;

@end
