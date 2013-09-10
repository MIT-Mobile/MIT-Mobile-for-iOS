/* This is a more flexible reimplementation of UISearchDisplayController
 * mainly for keeping up the overlay for searches where we don't want to
 * make network calls until the search button is pressed.
 *
 * The user is responsible for controlling the search results table view
 * and when it (dis)appears.
 *
 * Other differences from UISearchDisplayController are documented below.
 */

#import <UIKit/UIKit.h>

@interface MITSearchDisplayController : NSObject <UISearchBarDelegate>
@property (nonatomic, weak) UIViewController *searchContentsController;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) id<UISearchBarDelegate> delegate;
@property (nonatomic, getter=isActive) BOOL active;

// give user control over the table view
// currently, setting this 
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, weak) id<UITableViewDataSource> searchResultsDataSource;
@property (nonatomic, weak) id<UITableViewDelegate> searchResultsDelegate;

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (id)initWithFrame:(CGRect)frame searchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;

// give user access to more granular search UI states
- (void)focusSearchBarAnimated:(BOOL)animated;
- (void)unfocusSearchBarAnimated:(BOOL)animated;
- (void)showSearchOverlayAnimated:(BOOL)animated;
- (void)hideSearchOverlayAnimated:(BOOL)animated;

@end
