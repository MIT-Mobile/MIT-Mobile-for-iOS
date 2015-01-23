#import "MITPeopleSearchHandler.h"
#import "MITPeopleResource.h"
#import "MITPeopleModelController.h"

@interface MITPeopleSearchHandler()

@property (strong, nonatomic) MITPeopleModelController *modelController;

@end

@implementation MITPeopleSearchHandler

- (MITPeopleModelController *)modelController
{
    if( !_modelController )
    {
        _modelController = [MITPeopleModelController new];
    }
    
    return _modelController;
}

- (void)performSearchWithCompletionHandler:(void(^)(BOOL isSuccess))completionHandler
{
	// save search tokens for drawing table cells
    [self updateSearchTokensForSearchQuery:[self.searchTerms lowercaseString]];
    
	self.searchCancelled = NO;
    
    NSString *currentQueryString = self.searchTerms;

    [MITPeopleResource peopleMatchingQuery:currentQueryString loaded:^(NSArray *objects, NSError *error)
    {
        if (error)
        {
            self.searchResults = nil;
        }
        else if (!self.searchCancelled && (self.searchTerms == currentQueryString))
        {
            self.searchResults = objects;
        }
        
        if( completionHandler ) completionHandler( self.searchResults != nil );
    }];
}

- (void)updateSearchTokensForSearchQuery:(NSString *)searchQuery
{
    NSArray *searchTokens = [searchQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    searchTokens = [searchTokens sortedArrayUsingComparator:^NSComparisonResult(NSString *string1, NSString *string2) {
        return [@([string1 length]) compare:@([string2 length])];
    }];
    
	self.searchTokens = searchTokens;
}

- (NSMutableAttributedString *)hightlightSearchTokenWithinString:(NSString *)searchResultStr currentFont:(UIFont *)labelFont
{
    if( searchResultStr == nil )
    {
        return nil;
    }
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:labelFont.pointSize];   // This assumes labelFont will be using the systemFont
    
    __block NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:searchResultStr];
    [self.searchTokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger idx, BOOL *stop) {
        NSRange boldRange = [searchResultStr rangeOfString:token options:NSCaseInsensitiveSearch];
        
        if (boldRange.location != NSNotFound) {
            [attributeString setAttributes:@{NSFontAttributeName : boldFont} range:boldRange];
        }
    }];
    
    return attributeString;
}

#pragma mark - recents

- (BOOL)addRecentSearchTerm:(NSString *)recentSearchTerm
{
    NSError *error = nil;
    [self.modelController addRecentSearchTerm:recentSearchTerm error:error];
    
    return error == nil;
}

- (NSArray *)recentSearchTermsWithFilterString:(NSString *)filterString
{
    return [self.modelController recentSearchTermsWithFilterString:filterString];
}

- (BOOL)clearRecentSearches
{
    NSError *error = nil;
    [self.modelController clearRecentSearchTermsWithError:error];
    
    return error == nil;
}

@end
