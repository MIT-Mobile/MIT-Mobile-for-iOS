#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITSearchEffects.h"

NSInteger strLenSort(NSString *str1, NSString *str2, void *context);

@interface PeopleSearchViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, JSONLoadedDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
	
	NSMutableArray *recents;
	UISearchDisplayController *searchController;
	NSArray *searchResults;
	NSString *searchTerms;
	NSArray *searchTokens;
	UIView *loadingView;
	MITSearchEffects *searchBackground;
	UISearchBar *theSearchBar;
	BOOL didBeginExternalSearchBeforeLoading;
	BOOL requestWasDispatched;
	MITMobileWebAPI *api;
	UIView *recentlyViewedHeader;
}

- (void)reloadIfDidExternalSearch;
- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)cancelSearch;
- (void)performSearch;
- (void)showLoadingView;
- (void)cleanUpConnection;
- (void)phoneIconTapped;
- (void)showActionSheet;

@property (nonatomic, retain) NSMutableArray *recents;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) MITSearchEffects *searchBackground;

@end
