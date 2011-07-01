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
@property (nonatomic,retain) NSArray *cachedResults;
- (void)rebuildSearchResults;
- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location
                          withRegularExpression:(NSRegularExpression*)regex;
- (NSDictionary*)searchCategoriesForLocation:(FacilitiesLocation*)location
                       WithRegularExpression:(NSRegularExpression*)regex;
- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location
                    withRegularExpression:(NSRegularExpression*)regex;
@end

@implementation FacilitiesLocationSearch
@synthesize cachedResults = _cachedResults;
@synthesize searchesCategories = _searchesCategories;
@synthesize showHiddenBuildings = _showHiddenBuildings;
@dynamic category;
@dynamic searchString;

- (id)init {
    self = [super init];
    if (self) {
        self.cachedResults = nil;
        self.searchesCategories = NO;
        self.showHiddenBuildings = NO;
        self.category = nil;
        self.searchString = nil;
    }
    
    return self;
}

#pragma mark - Dynamic Accessor/Mutator
- (void)setCategory:(FacilitiesCategory *)category {
   self.cachedResults = nil;
    
    [_category release];
    _category = [category retain];
}

- (FacilitiesCategory*)category {
    return _category;
}

- (void)setSearchString:(NSString *)searchString {
    self.cachedResults = nil;
    
    [_searchString release];
    if (searchString) {
        _searchString = [[NSString alloc] initWithString:searchString];
    }
}

- (NSString *)searchString {
    return [[_searchString copy] autorelease];
}

#pragma mark - Public Methods
- (NSArray*)searchResults {
    if (self.cachedResults == nil) {
        [self rebuildSearchResults];
    }
    
    return self.cachedResults;
}

#pragma mark - Private Methods
- (void)rebuildSearchResults {
    FacilitiesLocationData *fld = [FacilitiesLocationData sharedData];
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
    
    NSString *pattern = [NSString stringWithFormat:@".*%@.*",[NSRegularExpression escapedPatternForString:self.searchString]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    
    for (FacilitiesLocation *location in locations) {
        if ([matchedLocations containsObject:location]) {
            continue;
        }
        
        NSDictionary *matchResult = [self searchNameAndNumberForLocation:location
                                                   withRegularExpression:regex];
        if (matchResult) {
            [searchResults addObject:matchResult];
            [matchedLocations addObject:[matchResult objectForKey:FacilitiesSearchResultLocationKey]];
            continue;
        }
        
        if (self.searchesCategories) {
            // Check for any matching categories
            matchResult = [self searchCategoriesForLocation:location
                                      WithRegularExpression:regex];
            if (matchResult) {
                [searchResults addObject:matchResult];
                [matchedLocations addObject:[matchResult objectForKey:FacilitiesSearchResultLocationKey]];
                continue;
            }
        }
        
        // Still nothing, check the contents
        matchResult = [self searchContentForLocation:location
                               withRegularExpression:regex];
        if (matchResult) {
            [searchResults addObject:matchResult];
            [matchedLocations addObject:[matchResult objectForKey:FacilitiesSearchResultLocationKey]];
        }
    }
    
    self.cachedResults = [searchResults allObjects];
}

- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location withRegularExpression:(NSRegularExpression*)regex {
    NSString *matchString = [location displayString];
    NSUInteger matchCount = [regex numberOfMatchesInString:matchString
                                                   options:0
                                                     range:NSMakeRange(0,[matchString length])];
    
    if (matchCount > 0) {
        NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
        [matchData setObject:location
                      forKey:FacilitiesSearchResultLocationKey];
        [matchData setObject:[location displayString]
                      forKey:FacilitiesSearchResultDisplayStringKey];
        [matchData setObject:FacilitiesMatchTypeLocationNameOrNumber
                      forKey:FacilitiesSearchResultMatchTypeKey];
        return [NSDictionary dictionaryWithDictionary:matchData];
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
            NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
            [matchData setObject:location
                          forKey:FacilitiesSearchResultLocationKey];
    
            [matchData setObject:[location displayString]
                          forKey:FacilitiesSearchResultDisplayStringKey];
            [matchData setObject:FacilitiesMatchTypeLocationCategory
                          forKey:FacilitiesSearchResultMatchTypeKey];
            [matchData setObject:category
                          forKey:FacilitiesSearchResultMatchObjectKey];
            return [NSDictionary dictionaryWithDictionary:matchData];
        }
    }
    
    return nil;
}

- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location withRegularExpression:(NSRegularExpression*)regex {
    for (FacilitiesContent *content in location.contents) {
        NSMutableSet *names = [NSMutableSet setWithObject:content.name];
        [names addObjectsFromArray:content.altname];
        
        for (NSString *name in names) {
            NSUInteger matchCount = [regex numberOfMatchesInString:name
                                                           options:0
                                                             range:NSMakeRange(0, [name length])];
            
            if (matchCount > 0) {
                NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
                [matchData setObject:location
                              forKey:FacilitiesSearchResultLocationKey];
               
                NSString *displayString = nil;
                if (location.number && ([location.number length] > 0)) {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.number,name];
                } else {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.name,name];
                }
                [matchData setObject:displayString
                              forKey:FacilitiesSearchResultDisplayStringKey];
                [matchData setObject:FacilitiesMatchTypeContentName
                              forKey:FacilitiesSearchResultMatchTypeKey];
                [matchData setObject:content
                              forKey:FacilitiesSearchResultMatchObjectKey];
                return [NSDictionary dictionaryWithDictionary:matchData];
            }
        }
        
        
        if (self.searchesCategories) {
            for (FacilitiesCategory *category in content.categories) {
                NSString *catName = category.name;
                NSUInteger matchCount = [regex numberOfMatchesInString:catName
                                                               options:0
                                                                 range:NSMakeRange(0, [catName length])];
                
                if (matchCount > 0) {
                    NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
                    [matchData setObject:location
                                  forKey:FacilitiesSearchResultLocationKey];
                    
                    [matchData setObject:[location displayString]
                                  forKey:FacilitiesSearchResultDisplayStringKey];
                    [matchData setObject:FacilitiesMatchTypeContentCategory
                                  forKey:FacilitiesSearchResultMatchTypeKey];
                    [matchData setObject:category
                                  forKey:FacilitiesSearchResultMatchObjectKey];
                    return [NSDictionary dictionaryWithDictionary:matchData];
                }
            }
        }
    }
    
    return nil;
}

@end
