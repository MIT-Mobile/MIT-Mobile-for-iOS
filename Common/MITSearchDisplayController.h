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

@protocol MITSearchDisplayDelegate

@optional

- (void)searchOverlayTapped;

@end


@interface MITSearchDisplayController : NSObject <UISearchBarDelegate> {
    
    BOOL _active;
    UIControl *_searchOverlay;
    UISearchBar *_searchBar;
    
    UIViewController *_searchContentsController;

    // we will only display/hide this when the search/cancel controls are pressed.
    // most methods that implement UISearchDisplayDelegate will be ignored.
    UITableView *_searchResultsTableView;
    id<UITableViewDataSource> _searchResultsDataSource;
    id<UITableViewDelegate> _searchResultsDelegate;
    BOOL _searchResultsTableIsDefault;

    // the original delegate assigned to _searchBar, if any.
    // when this class is initialized, _searchBar.delegate will be reassigned
    // to self; all UISearchBarDelegate messages will be acted upon first
    // by this class before being passed on to _searchBarDelegate
    id<UISearchBarDelegate, MITSearchDisplayDelegate> _delegate;
}

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (id)initWithFrame:(CGRect)frame searchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;

@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, readonly) UIViewController *searchContentsController;
@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic, assign) id<UISearchBarDelegate, MITSearchDisplayDelegate> delegate;

// give user control over the table view
// currently, setting this 
@property (nonatomic, retain) UITableView *searchResultsTableView;
@property (nonatomic, assign) id<UITableViewDataSource> searchResultsDataSource;
@property (nonatomic, assign) id<UITableViewDelegate> searchResultsDelegate;

// give user access to more granular search UI states
- (void)focusSearchBarAnimated:(BOOL)animated;
- (void)unfocusSearchBarAnimated:(BOOL)animated;
- (void)showSearchOverlayAnimated:(BOOL)animated;
- (void)hideSearchOverlayAnimated:(BOOL)animated;

@end
