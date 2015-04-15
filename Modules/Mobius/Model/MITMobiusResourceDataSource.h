#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITMobiusQuickSearchType) {
    MITMobiusQuickSearchRoomSet = 0,
    MITMobiusQuickSearchResourceType,
};

@interface MITMobiusResourceDataSource : NSObject
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

+ (NSURL*)defaultServerURL;
- (instancetype)init;
- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;
- (void)getObjectsForRoute:(MITMobiusQuickSearchType)type completion:(void(^)(NSArray* objects, NSError *error))block;
- (NSDictionary*)resourcesGroupedByKey:(NSString*)key withManagedObjectContext:(NSManagedObjectContext*)context;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end
