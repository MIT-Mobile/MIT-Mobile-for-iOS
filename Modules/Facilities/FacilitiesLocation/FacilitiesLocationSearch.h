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

@interface FacilitiesLocationSearch : NSObject
@property (nonatomic) BOOL searchesCategories;
@property (nonatomic) BOOL showHiddenBuildings;
@property (nonatomic,copy) NSString *searchString;
@property (nonatomic,strong) FacilitiesCategory *category;
@property (nonatomic,readonly,copy) NSArray *searchResults;

@end
