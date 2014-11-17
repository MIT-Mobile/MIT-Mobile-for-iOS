#import <UIKit/UIKit.h>
#import "MITNewsSearchController.h"

@interface MITNewsRecentSearchController : UITableViewController

@property MITNewsSearchController *searchController;
@property (nonatomic, readonly) UIActionSheet *confirmSheet;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;

@end
