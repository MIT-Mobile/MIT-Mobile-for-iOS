#import <Foundation/Foundation.h>

@interface WorldCatSearchController : NSObject  <UITableViewDataSource, UITableViewDelegate> {
    
}

- (void) doSearch:(NSString *)theSearchTerms;
- (void)clearSearch;

@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSNumber *nextIndex;
@property (nonatomic, retain) UITableView *searchResultsTableView;


@end
