#import <UIKit/UIKit.h>
#import "MITSearchDisplayController.h"

@interface PeopleSearchViewController : UITableViewController
@property (nonatomic,strong) IBOutlet MITSearchDisplayController *searchController;
@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic,copy) NSArray *searchResults;

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;
- (void)showActionSheet;

@end
