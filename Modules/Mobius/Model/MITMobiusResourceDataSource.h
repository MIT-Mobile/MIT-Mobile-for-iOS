#import <Foundation/Foundation.h>

@interface MITMobiusResourceDataSource : NSObject
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

+ (NSURL*)defaultServerURL;
- (instancetype)init;
- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end
