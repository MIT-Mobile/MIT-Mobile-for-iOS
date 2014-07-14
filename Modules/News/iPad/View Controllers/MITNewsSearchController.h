#import <UIKit/UIKit.h>

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController

@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)showSearchRecents;
- (void)getResultsForString:(NSString *)searchTerm;
- (UISearchBar *)returnSearchBarWithWidth:(CGFloat)width;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end