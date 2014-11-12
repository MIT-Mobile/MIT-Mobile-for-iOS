#import <UIKit/UIKit.h>
#import "MITNewsSearchController.h"

@interface MITNewsRecentSearchController : UIViewController

@property MITNewsSearchController *searchController;
@property (nonatomic, readonly) UIActionSheet *confirmSheet;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;
- (void)initializeTable;

@end
