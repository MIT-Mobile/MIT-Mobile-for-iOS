#import <UIKit/UIKit.h>

@interface PeopleSearchViewController : UITableViewController <UISearchDisplayDelegate>

@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;

- (NSArray *)searchResults;

@end
