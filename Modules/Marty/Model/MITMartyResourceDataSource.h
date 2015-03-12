#import <Foundation/Foundation.h>

@interface MITMartyResourceDataSource : NSObject
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

- (instancetype)init;
- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMartyResourceDataSource* dataSource, NSError *error))block;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end
