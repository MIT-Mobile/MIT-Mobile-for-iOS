#import <UIKit/UIKit.h>
#import "MITNewsSearchController.h"

@interface MITMartyRecentSearchController : UITableViewController

@property MITNewsSearchController *searchController;
@property (nonatomic, readonly) UIActionSheet *confirmSheet;

- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;

@end
