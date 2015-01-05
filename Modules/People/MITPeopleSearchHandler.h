#import <Foundation/Foundation.h>

@interface MITPeopleSearchHandler : NSObject

@property (nonatomic, copy) NSString *searchTerms;
@property (nonatomic, copy) NSArray *searchTokens;
@property (nonatomic, copy) NSArray *searchResults;

@property BOOL searchCancelled;

- (void)performSearchWithCompletionHandler:(void(^)(BOOL isSuccess))completionHandler;
- (void)updateSearchTokensForSearchQuery:(NSString *)searchQuery;

- (NSMutableAttributedString *)hightlightSearchTokenWithinString:(NSString *)searchResultStr currentFont:(UIFont *)labelFont;

- (BOOL)addRecentSearchTerm:(NSString *)recentSearchTerm;
- (NSArray *)recentSearchTermsWithFilterString:(NSString *)filterString;
- (BOOL)clearRecentSearches;

@end
