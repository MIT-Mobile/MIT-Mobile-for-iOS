#import <UIKit/UIKit.h>
#import "MITNewsSearchController.h"

@interface MITNewsRecentSearchController : UIViewController

@property (nonatomic, readonly) UIActionSheet *confirmSheet;
- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;

@property MITNewsSearchController *searchController;

@end
