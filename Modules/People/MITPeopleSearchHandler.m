//
//  PeopleSearchHandler.m
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import "MITPeopleSearchHandler.h"
#import "MITPeopleResource.h"

@implementation MITPeopleSearchHandler

- (void)performSearchWithCompletionHandler:(void(^)(BOOL isSuccess))completionHandler
{
	// save search tokens for drawing table cells
    NSString *searchQuery = [self.searchTerms lowercaseString];
    NSArray *searchTokens = [searchQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    searchTokens = [searchTokens sortedArrayUsingComparator:^NSComparisonResult(NSString *string1, NSString *string2) {
        return [@([string1 length]) compare:@([string2 length])];
    }];
    
	self.searchTokens = searchTokens;
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

- (NSMutableAttributedString *) hightlightSearchTokenWithinString:(NSString *)searchResultStr currentFont:(UIFont *)labelFont
{
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

@end
