#import <UIKit/UIKit.h>
#import "MITSearchDisplayController.h"

NSInteger strLenSort(NSString *str1, NSString *str2, void *context);

@interface PeopleSearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MITSearchDisplayDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
	
    MITSearchDisplayController *searchController;
    UITableView *theTableView;
    UITableView *searchResultsTableView;
	NSArray *searchResults;
	NSString *searchTerms;
	NSArray *searchTokens;
	UIView *loadingView;
	UISearchBar *theSearchBar;
	BOOL _searchCancelled;
	UIView *recentlyViewedHeader;
}

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)showLoadingView;
- (void)phoneIconTapped;
- (void)showActionSheet;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIView *loadingView;

@end
