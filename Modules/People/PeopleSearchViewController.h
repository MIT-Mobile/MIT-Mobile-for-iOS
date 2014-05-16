#import <UIKit/UIKit.h>

@interface PeopleSearchViewController : UITableViewController <UISearchDisplayDelegate>
@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic,copy) NSArray *searchResults;

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;

@end
