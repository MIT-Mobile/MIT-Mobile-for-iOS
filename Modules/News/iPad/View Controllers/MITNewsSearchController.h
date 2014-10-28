#import <UIKit/UIKit.h>
#import "MITNewsStoriesDataSource.h"

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController <UISearchBarDelegate>

@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;
@property (weak, nonatomic) UISearchBar *searchBar;
- (void)showSearchRecents;
- (void)getResultsForString:(NSString *)searchTerm;
@property (nonatomic, strong) MITNewsDataSource *dataSource;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;
- (void)changeToMainStories;
- (void)changeToSearchStories;
- (void)reloadSearchData;

@end