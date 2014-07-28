#import <UIKit/UIKit.h>
#import "UITableView+DynamicSizing.h"

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController <UISearchBarDelegate, UITableViewDataSourceDynamicSizing>

@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchTableView;

- (void)showSearchRecents;
- (void)getResultsForString:(NSString *)searchTerm;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end