#import "MITSearchDisplayController.h"
#import "MITUIConstants.h"

#define kSearchOverlayAnimationDuration 0.4

@interface MITSearchDisplayController (Private)

- (void)showSearchOverlayAnimated:(BOOL)animated;
- (void)hideSearchOverlayAnimated:(BOOL)animated;
- (void)releaseSearchOverlay;
- (void)searchOverlayTapped;
- (void)setupSearchResultsTableView;

@end


@implementation MITSearchDisplayController

@synthesize searchBar = _searchBar,
searchContentsController = _searchContentsController,
searchResultsTableView = _searchResultsTableView,
delegate = _delegate;

@dynamic active, searchResultsDelegate, searchResultsDataSource;

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController
{
    if (self = [super init]) {
        _searchBar = searchBar;
        _searchBar.tintColor = SEARCH_BAR_TINT_COLOR;

        _searchBarDelegate = _searchBar.delegate;
        _searchBar.delegate = self;
        
        _searchContentsController = viewController;
        _delegate = nil;
        _searchResultsDelegate = nil;
        _searchResultsDataSource = nil;
        
        _searchResultsTableView = nil;
        
    }
    return self;
}

- (void)setSearchResultsTableView:(UITableView *)tableView {
    _searchResultsTableView = [tableView retain];
    _searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (tableView.delegate != nil) {
        _searchResultsDelegate = tableView.delegate;
    }
    if (tableView.dataSource != nil) {
        _searchResultsDataSource = tableView.dataSource;
    }
}

- (void)setSearchResultsDelegate:(id<UITableViewDelegate>)delegate {
    _searchResultsDelegate = delegate;
    _searchResultsTableView.delegate = delegate;
}

- (id<UITableViewDelegate>)searchResultsDelegate {
    return _searchResultsDelegate;
}

- (void)setSearchResultsDataSource:(id<UITableViewDataSource>)dataSource {
    _searchResultsDataSource = dataSource;
    _searchResultsTableView.dataSource = dataSource;
}

- (id<UITableViewDataSource>)searchResultsDataSource {
    return _searchResultsDataSource;
}

- (BOOL)active {
    return _active;
}

- (void)setActive:(BOOL)active {
    [self setActive:active animated:YES];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    if (active != _active) {
        _active = active;
        
        [_searchBar setShowsCancelButton:active animated:animated];

        if (active) {
            [self showSearchOverlayAnimated:animated];
            [_searchBar becomeFirstResponder];
        } else {
            [self hideSearchOverlayAnimated:animated];
            [_searchBar resignFirstResponder];
        }
    }
}

- (void)showSearchOverlayAnimated:(BOOL)animated {
	if (!_searchOverlay) {
        CGRect frame = CGRectMake(0.0, _searchBar.frame.size.height, _searchBar.frame.size.width, _searchContentsController.view.frame.size.height - _searchBar.frame.size.height);
		_searchOverlay = [[UIControl alloc] initWithFrame:frame];
        _searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        [_searchOverlay addTarget:self action:@selector(searchOverlayTapped) forControlEvents:UIControlEventTouchDown];
		_searchOverlay.alpha = 0.0;
		[_searchContentsController.view addSubview:_searchOverlay];
	}
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:kSearchOverlayAnimationDuration];
    }
    
	_searchOverlay.alpha = 1.0;
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)hideSearchOverlayAnimated:(BOOL)animated {
	if (_searchOverlay) {
        if (animated) {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:kSearchOverlayAnimationDuration];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(releaseSearchOverlay)];
        }
        
		_searchOverlay.alpha = 0.0;

        if (animated) {
            [UIView commitAnimations];
        }
	}
}

- (void)releaseSearchOverlay {
    [_searchOverlay removeFromSuperview];
    [_searchOverlay release];
    _searchOverlay = nil;
}

- (void)searchOverlayTapped {
    // if there are still search results, keep them up
	if ([_searchResultsTableView numberOfSections] && [_searchResultsTableView numberOfRowsInSection:0]) {
		[self setActive:NO animated:YES];
	} else {
		[self searchBarCancelButtonClicked:_searchBar];
	}
}

#pragma mark -
#pragma mark UISearchBarDelegate wrapper

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [_searchBarDelegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
        return [_searchBarDelegate searchBar:searchBar shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [_searchBarDelegate searchBar:searchBar textDidChange:searchText];
    }
    
    if ([_delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
        if ([_delegate searchDisplayController:nil shouldReloadTableForSearchString:searchText]) {
            [_searchResultsTableView reloadData];
        }
    }
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)]) {
        [_searchBarDelegate searchBarBookmarkButtonClicked:searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchBar.text = nil;
    [_searchResultsTableView removeFromSuperview];
    [self setActive:NO animated:YES];
    
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [_searchBarDelegate searchBarCancelButtonClicked:searchBar];
    }
}

/*
// available in OS 3.2 and later.
- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarResultsListButtonClicked:)]) {
        [_searchBarDelegate searchBarResultsListButtonClicked:searchBar];
    }
}
*/

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self setActive:NO animated:YES];
    
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [_searchBarDelegate searchBarSearchButtonClicked:searchBar];
    }
}

// called before searchDisplayControllerWillBeginSearch:
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self setActive:YES animated:YES];
    
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        return [_searchBarDelegate searchBarShouldBeginEditing:searchBar];
    }
    return YES;
}

// called between searchDisplayControllerWillEndSearch: and searchDisplayControllerDidEndSearch:
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if ([_delegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [_delegate searchDisplayControllerWillEndSearch:nil];
    }
    
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        return [_searchBarDelegate searchBarShouldEndEditing:searchBar];
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [_searchBarDelegate searchBarTextDidBeginEditing:searchBar];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if ([_searchBarDelegate respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [_searchBarDelegate searchBarTextDidEndEditing:searchBar];
    }
}

- (void)dealloc {
    [_searchResultsTableView release];
    [super dealloc];
}

@end
