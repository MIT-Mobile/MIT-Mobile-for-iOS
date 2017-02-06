#import <UIKit/UIKit.h>

@interface PeopleSearchViewController : UITableViewController

@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;

@property (nonatomic,strong) UISearchController *strongSearchDisplayController;

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;

- (NSArray *)searchResults;

@end
