#import <Foundation/Foundation.h>

typedef enum {
    BooksSearchingStatusNotLoaded,
    BooksSearchingStatusLoading,
    BooksSearchingStatusLoaded,
    BooksSearchingStatusFailed
} BooksSearchingStatus;

@interface WorldCatSearchController : NSObject  <UITableViewDataSource, UITableViewDelegate> {
    BooksSearchingStatus _searchingStatus;
    
}

- (void)doSearch:(NSString *)searchTerms;
- (void)clearSearch;

@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSNumber *totalResultsCount;
@property (nonatomic, retain) NSNumber *nextIndex;
@property (nonatomic, retain) UITableView *searchResultsTableView;
@property (nonatomic, retain) UIView *loadMoreView;
@property (nonatomic, assign) BooksSearchingStatus searchingStatus;
@property (nonatomic, assign) NSTimeInterval lastSearchAttempt;
@property (nonatomic, assign) UINavigationController *navigationController;
@property (nonatomic) BOOL parseError;



@end
