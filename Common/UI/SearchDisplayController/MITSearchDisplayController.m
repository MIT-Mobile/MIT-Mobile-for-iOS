#import "MITSearchDisplayController.h"
#import "MITUIConstants.h"

#define kSearchOverlayAnimationDuration 0.4

@interface MITSearchDisplayController ()
@property (nonatomic,weak) UIControl *searchOverlay;

- (void)searchOverlayTapped;
@end


@implementation MITSearchDisplayController
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
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        self.searchResultsTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        self.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)setSearchResultsTableView:(UITableView *)tableView {
    if (_searchResultsTableView != tableView) {
        _searchResultsTableView = tableView;
    }

    if (tableView.delegate) {
        _searchResultsDelegate = tableView.delegate;
    }
    if (tableView.dataSource) {
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
    if (self.searchOverlay) {
        [self.searchOverlay removeFromSuperview];
    } else {
        CGRect frame;

        if (self.searchResultsTableView) {
            frame = self.searchResultsTableView.frame;
        } else {
            CGFloat yOrigin = CGRectGetMinY(self.searchBar.frame) + CGRectGetHeight(self.searchBar.frame);
            CGSize containerSize = self.searchContentsController.view.bounds.size;
            frame = CGRectMake(0.0, yOrigin, containerSize.width, containerSize.height - yOrigin);
        }

        UIControl *searchOverlay = [[UIControl alloc] initWithFrame:frame];
        searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        [searchOverlay addTarget:self
                          action:@selector(searchOverlayTapped)
                forControlEvents:UIControlEventTouchDown];

        searchOverlay.alpha = 0.;
        [self.searchContentsController.view addSubview:searchOverlay];
        self.searchOverlay = searchOverlay;

        NSTimeInterval animationDuration = (animated ? kSearchOverlayAnimationDuration : 0.);
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             self.searchOverlay.alpha = 1.;
                         }];
    }
}

- (void)hideSearchOverlayAnimated:(BOOL)animated {
    if (self.searchOverlay) {
        NSTimeInterval animationDuration = (animated ? kSearchOverlayAnimationDuration : 0.);
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             self.searchOverlay.alpha = 0.;
                         }
         completion:^(BOOL finished) {
             [self.searchOverlay removeFromSuperview];
         }];
    }
}

- (void)searchOverlayTapped {
    if ([self.searchBar.text length]) {
		[self setActive:NO animated:YES];
	} else {
		[self searchBarCancelButtonClicked:self.searchBar];
	}
}

- (void)focusSearchBarAnimated:(BOOL)animated {
    [self.searchBar becomeFirstResponder];
}

- (void)unfocusSearchBarAnimated:(BOOL)animated {
    [self.searchBar resignFirstResponder];
}

#pragma mark UISearchBarDelegate forwarding

#pragma mark - UISearchBarDelegate wrapper

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
    self.searchBar.text = nil;
    [self setActive:NO animated:YES];
    [self.searchResultsTableView removeFromSuperview];
    
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
    [searchBar setShowsCancelButton:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:searchBar];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [self.delegate searchBarTextDidEndEditing:searchBar];
    }
}

@end
