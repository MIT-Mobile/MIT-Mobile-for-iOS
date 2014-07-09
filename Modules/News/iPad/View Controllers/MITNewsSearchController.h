#import <UIKit/UIKit.h>

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController

- (UISearchBar *)returnSearchBar;
@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
- (void)showSearchRecents;

@property (nonatomic, strong) NSArray *stories;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end