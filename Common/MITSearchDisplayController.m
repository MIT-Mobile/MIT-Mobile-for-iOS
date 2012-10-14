#import "MITSearchDisplayController.h"
#import "MITUIConstants.h"

#define kSearchOverlayAnimationDuration 0.4

@interface MITSearchDisplayController (Private)

- (void)releaseSearchOverlay;
- (void)searchOverlayTapped;

@end



@implementation MITSearchDisplayController

@synthesize searchBar = _searchBar,
searchContentsController = _searchContentsController,
searchResultsTableView = _searchResultsTableView,
delegate = _delegate,
searchResultsDelegate = _searchResultsDelegate,
searchResultsDataSource = _searchResultsDataSource,
active = _active;

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController
{
   CGRect frame = CGRectMake(0.0,
                             searchBar.frame.size.height,
                             viewController.view.frame.size.width,
                             viewController.view.frame.size.height - _searchBar.frame.size.height);
   return [self initWithFrame:frame 
                    searchBar:searchBar
           contentsController:viewController];
}

- (id)initWithFrame:(CGRect)frame searchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _searchBar = searchBar;
        _searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        self.searchResultsTableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
        self.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _searchResultsTableIsDefault = YES;
    }
    
    return self;
}

- (void)setSearchResultsTableView:(UITableView *)tableView {
    if (_searchResultsTableView != tableView) {
        if (_searchResultsTableIsDefault)
            [_searchResultsTableView release];
        _searchResultsTableIsDefault = NO;
        _searchResultsTableView = [tableView retain];
    }
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

- (void)setSearchResultsDataSource:(id<UITableViewDataSource>)dataSource {
    _searchResultsDataSource = dataSource;
    _searchResultsTableView.dataSource = dataSource;
}

- (void)setActive:(BOOL)active {
    [self setActive:active animated:YES];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    if (active != _active) {
        _active = active;
        
        if (_active) {
            [self showSearchOverlayAnimated:animated];
            [self focusSearchBarAnimated:animated];
        } else {
            [self hideSearchOverlayAnimated:animated];
            [self unfocusSearchBarAnimated:animated];
        }
    }
}

- (void)showSearchOverlayAnimated:(BOOL)animated {
    if (_searchOverlay) {
        [_searchOverlay removeFromSuperview];
    }
    else {
        CGRect frame;
        if (self.searchResultsTableView != nil) {
            frame = _searchResultsTableView.frame;
        } else {
            CGFloat yOrigin = _searchBar.frame.origin.y + _searchBar.frame.size.height;
            CGSize containerSize = _searchContentsController.view.frame.size;
            frame = CGRectMake(0.0, yOrigin, containerSize.width, containerSize.height - yOrigin);
        }
        _searchOverlay = [[UIControl alloc] initWithFrame:frame];
        _searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        [_searchOverlay addTarget:self
                           action:@selector(searchOverlayTapped)
                 forControlEvents:UIControlEventTouchDown];
    }
    
    _searchOverlay.alpha = 0.0;
    [_searchContentsController.view addSubview:_searchOverlay];

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
            _searchOverlay.alpha = 0.0;
            [UIView commitAnimations];
        } else {
            [self releaseSearchOverlay];
        }
    }
}

- (void)releaseSearchOverlay {
    [_searchOverlay removeFromSuperview];
    [_searchOverlay release];
    _searchOverlay = nil;
}

- (void)searchOverlayTapped {
    if ([_searchBar.text length]) {
		[self setActive:NO animated:YES];
	} else {
		[self searchBarCancelButtonClicked:_searchBar];
	}
    
    if ([self.delegate respondsToSelector:@selector(searchOverlayTapped)]) {
        [self.delegate searchOverlayTapped];
    }
}

- (void)focusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:YES animated:animated];
    [_searchBar becomeFirstResponder];
}

- (void)unfocusSearchBarAnimated:(BOOL)animated {
    [_searchBar setShowsCancelButton:NO animated:animated];
    [_searchBar resignFirstResponder];
    _active = NO;
}

#pragma mark UISearchBarDelegate forwarding

#pragma mark -
#pragma mark UISearchBarDelegate wrapper

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate searchBar:searchBar shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:searchBar textDidChange:searchText];
    }
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)]) {
        [self.delegate searchBarBookmarkButtonClicked:searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchBar.text = nil;
    [self setActive:NO animated:YES];
    [_searchResultsTableView removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:searchBar];
    }
}

// available in OS 3.2 and later.
- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarResultsListButtonClicked:)]) {
        [self.delegate searchBarResultsListButtonClicked:searchBar];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self unfocusSearchBarAnimated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:searchBar];
    }
}

// called before searchDisplayControllerWillBeginSearch:
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        return [self.delegate searchBarShouldBeginEditing:searchBar];
    }
    return YES;
}

// called between searchDisplayControllerWillEndSearch: and searchDisplayControllerDidEndSearch:
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        return [self.delegate searchBarShouldEndEditing:searchBar];
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self setActive:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:searchBar];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [self.delegate searchBarTextDidEndEditing:searchBar];
    }
}

- (void)dealloc {
    self.delegate = nil;
    _searchResultsDelegate = nil;
    _searchResultsDataSource = nil;
    self.searchResultsTableView = nil;
    
    _searchBar = nil;
    _searchContentsController = nil;
    [super dealloc];
}

@end
