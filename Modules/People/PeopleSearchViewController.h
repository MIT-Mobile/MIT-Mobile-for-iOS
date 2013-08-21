#import <UIKit/UIKit.h>
#import "MITSearchDisplayController.h"

@interface PeopleSearchViewController : UIViewController
@property (nonatomic,strong) MITSearchDisplayController *searchController;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,copy) NSArray *searchResults;

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;
- (void)showActionSheet;

@end
