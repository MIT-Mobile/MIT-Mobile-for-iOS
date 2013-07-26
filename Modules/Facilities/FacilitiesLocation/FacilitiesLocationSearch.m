#import "FacilitiesLocationSearch.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesContent.h"

NSString * const FacilitiesSearchResultLocationKey = @"FacilitiesSearchResultLocation";
NSString * const FacilitiesSearchResultDisplayStringKey = @"FacilitiesSearchResultDisplayString";
NSString * const FacilitiesSearchResultMatchTypeKey = @"FacilitiesSearchResultMatchType";
NSString * const FacilitiesSearchResultMatchObjectKey = @"FacilitiesSearchResultMatchObject";

NSString * const FacilitiesMatchTypeLocationNameOrNumber = @"FacilitiesMatchTypeLocationNameOrNumber";
NSString * const FacilitiesMatchTypeLocationCategory = @"FacilitiesMatchTypeLocationCategory";
NSString * const FacilitiesMatchTypeContentName = @"FacilitiesMatchTypeContentName";
NSString * const FacilitiesMatchTypeContentCategory = @"FacilitiesMatchTypeContentCategory";

@interface FacilitiesLocationSearch ()
@property (nonatomic,copy) NSArray *searchResults;

- (void)loadSearchResults;
- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location
                                   forSubstring:(NSString*)substring;
- (NSDictionary*)searchCategoriesForLocation:(FacilitiesLocation*)location
                       WithRegularExpression:(NSRegularExpression*)regex;
- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location
                             forSubstring:(NSString*)substring;
@end

@implementation FacilitiesLocationSearch
- (id)init {
    self = [super init];
    if (self) {
        _searchResults = nil;
        _searchesCategories = NO;
        _showHiddenBuildings = NO;
        _category = nil;
        _searchString = nil;
    }
    
    return self;
}

#pragma mark - Custom Property Setters/Getters
- (void)setCategory:(FacilitiesCategory *)category {
    self.searchResults = nil;
    _category = category;
}

- (void)setSearchString:(NSString *)searchString {
    self.searchResults = nil;
    _searchString = [searchString copy];
}

- (NSArray*)searchResults {
    if (_searchResults == nil) {
        [self loadSearchResults];
    }
    
    return _searchResults;
}

#pragma mark - Private Methods
- (void)loadSearchResults {
    FacilitiesLocationData *fld = [FacilitiesLocationData sharedData];
    NSString *searchString = [NSString stringWithString:self.searchString];
    NSMutableArray *locations = nil;
    NSMutableSet *matchedLocations = [NSMutableSet set];
    NSMutableSet *searchResults = [NSMutableSet set];
    
    if (self.category) {
        locations = [NSMutableArray arrayWithArray:[fld locationsInCategory:self.category.uid]];
    } else {
        locations = [NSMutableArray arrayWithArray:[fld allLocations]];
    }
    
    if (self.showHiddenBuildings == NO) {
        [locations removeObjectsInArray:[fld hiddenBuildings]];
    }
    
    NSString *pattern = [NSString stringWithFormat:@".*%@.*",[NSRegularExpression escapedPatternForString:searchString]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    
    for (FacilitiesLocation *location in locations) {
        if ([matchedLocations containsObject:location]) {
            continue;
        }
        
        NSDictionary *matchResult = [self searchNameAndNumberForLocation:location
                                                            forSubstring:searchString];
        if (matchResult) {
            [searchResults addObject:matchResult];
            [matchedLocations addObject:matchResult[FacilitiesSearchResultLocationKey]];
            continue;
        }
        
        if (self.searchesCategories) {
            // Check for any matching categories
            matchResult = [self searchCategoriesForLocation:location
                                      WithRegularExpression:regex];
            if (matchResult) {
                [searchResults addObject:matchResult];
                [matchedLocations addObject:matchResult[FacilitiesSearchResultLocationKey]];
                continue;
            }
        }
        
        // Still nothing, check the contents
        matchResult = [self searchContentForLocation:location
                                        forSubstring:searchString];
        if (matchResult) {
            [searchResults addObject:matchResult];
            [matchedLocations addObject:matchResult[FacilitiesSearchResultLocationKey]];
        }
    }
    
    self.searchResults = [searchResults allObjects];
}

- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location forSubstring:(NSString*)substring {
    NSRange substringRange = [[location displayString] rangeOfString:substring
                                                             options:NSCaseInsensitiveSearch];
    if (substringRange.location != NSNotFound) {
        return @{FacilitiesSearchResultLocationKey : location,
                 FacilitiesSearchResultDisplayStringKey : [location displayString],
                 FacilitiesSearchResultMatchTypeKey : FacilitiesMatchTypeLocationNameOrNumber};
    }
    
    return nil;
}

- (NSDictionary*)searchCategoriesForLocation:(FacilitiesLocation*)location WithRegularExpression:(NSRegularExpression*)regex {
    for (FacilitiesCategory *category in location.categories) {
        NSString *catName = category.name;
        NSUInteger matchCount = [regex numberOfMatchesInString:catName
                                                       options:0
                                                         range:NSMakeRange(0, [catName length])];
        
        if (matchCount > 0) {
            return @{FacilitiesSearchResultLocationKey : location,
                     FacilitiesSearchResultDisplayStringKey : [location displayString],
                     FacilitiesSearchResultMatchTypeKey : FacilitiesMatchTypeLocationCategory,
                     FacilitiesSearchResultMatchObjectKey : category};
        }
    }
    
    return nil;
}

- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location forSubstring:(NSString*)substring {
    NSMutableSet *names = [NSMutableSet setWithCapacity:1];
    
    for (FacilitiesContent *content in location.contents) {
        [names removeAllObjects];
        [names addObject:content.name];
        [names addObjectsFromArray:content.altname];
        
        for (NSString *name in names) {
            NSRange substrRange = [name rangeOfString:substring
                                              options:NSCaseInsensitiveSearch];
            
            if (substrRange.location != NSNotFound) {
                NSString *displayString = nil;
                if (location.number && ([location.number length] > 0)) {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.number,name];
                } else {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.name,name];
                }
                
                return @{FacilitiesSearchResultLocationKey : location,
                         FacilitiesSearchResultDisplayStringKey : displayString,
                         FacilitiesSearchResultMatchTypeKey : FacilitiesMatchTypeContentName,
                         FacilitiesSearchResultMatchObjectKey : content};
            }
        }
        
        
        if (self.searchesCategories && ([content.categories count] > 0)) {
            for (FacilitiesCategory *category in content.categories) {
                NSRange substrRange = [category.name rangeOfString:substring
                                                           options:NSCaseInsensitiveSearch];
                
                if (substrRange.location != NSNotFound) {
                    return @{FacilitiesSearchResultLocationKey : location,
                             FacilitiesSearchResultDisplayStringKey : [location displayString],
                             FacilitiesSearchResultMatchTypeKey : FacilitiesMatchTypeContentCategory,
                             FacilitiesSearchResultMatchObjectKey : category};
                }
            }
        }
    }
    
    return nil;
}

@end
