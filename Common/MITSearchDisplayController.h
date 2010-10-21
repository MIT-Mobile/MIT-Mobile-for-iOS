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

// we implement UISearchBarDelegate for default actions if the user does not.
// however the user is encouraged to assign searchBar.delegate before
// initializing this class.
@interface MITSearchDisplayController : NSObject <UISearchBarDelegate> {
    
    BOOL _active;
    UIControl *_searchOverlay;
    UISearchBar *_searchBar;
    UIViewController *_searchContentsController;
    
    // we will only display/hide this when the search/cancel controls are pressed.
    // most methods that implement UISearchDisplayDelegate will be ignored.
    UITableView *_searchResultsTableView;
    id<UISearchDisplayDelegate> _delegate;
    id<UITableViewDelegate> _searchResultsDelegate;
    id<UITableViewDataSource> _searchResultsDataSource;
    
    // the original delegate assigned to _searchBar, if any.
    // when this class is initialized, _searchBar.delegate will be reassigned
    // to self; all UISearchBarDelegate messages will be acted upon first
    // by this class before being passed on to _searchBarDelegate
    id<UISearchBarDelegate> _searchBarDelegate;
    
}

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)active animated:(BOOL)animated;

@property (nonatomic, assign) BOOL active;
@property (nonatomic, readonly) UIViewController *searchContentsController;
@property (nonatomic, readonly) UISearchBar *searchBar;

// give user control over the table view
// currently, setting this 
@property (nonatomic, retain) UITableView *searchResultsTableView;
@property (nonatomic, assign) id<UISearchDisplayDelegate> delegate;
@property (nonatomic, assign) id<UITableViewDataSource> searchResultsDataSource;
@property (nonatomic, assign) id<UITableViewDelegate> searchResultsDelegate;

@end
