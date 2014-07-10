#import <UIKit/UIKit.h>

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController

@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
@property (nonatomic, strong) NSArray *stories;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)showSearchRecents;
- (void)getResultsForString:(NSString *)searchTerm;
- (UISearchBar *)returnSearchBar;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end