#import <Foundation/Foundation.h>


extern NSString * const FacilitiesSearchResultLocationKey;
extern NSString * const FacilitiesSearchResultDisplayStringKey;
extern NSString * const FacilitiesSearchResultMatchTypeKey;
extern NSString * const FacilitiesSearchResultMatchObjectKey;

extern NSString * const FacilitiesMatchTypeLocationNameOrNumber;
extern NSString * const FacilitiesMatchTypeLocationCategory;
extern NSString * const FacilitiesMatchTypeContentName;
extern NSString * const FacilitiesMatchTypeContentCategory;

@class FacilitiesCategory;

@interface FacilitiesLocationSearch : NSObject {
    NSString *_searchString;
    FacilitiesCategory *_category;
    NSArray *_cachedResults;
    BOOL _searchesCategories;
    BOOL _showHiddenBuildings;
}

@property (nonatomic) BOOL searchesCategories;
@property (nonatomic) BOOL showHiddenBuildings;
@property (nonatomic,copy) NSString *searchString;
@property (nonatomic,retain) FacilitiesCategory *category;

- (NSArray*)searchResults;
@end
