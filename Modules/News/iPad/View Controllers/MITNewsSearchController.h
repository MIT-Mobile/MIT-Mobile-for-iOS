#import <UIKit/UIKit.h>
#import "UITableView+DynamicSizing.h"

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController <UISearchBarDelegate, UITableViewDataSourceDynamicSizing>

@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) UISearchBar *searchBar;
- (void)showSearchRecents;
- (void)getResultsForString:(NSString *)searchTerm;
@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError * error))block;
- (void)bringBackStories;
- (void)hideStories;
- (void)reloadData;

@end