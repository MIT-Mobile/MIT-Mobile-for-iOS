#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITMobiusRequestType) {
    MITMobiusRequestTypeResourceType,
    MITMobiusRequestTypeResourceRoomset
};

typedef NS_ENUM(NSInteger, MITMobiuQuickSearchType) {
    MITMobiusShopsAndLabs = 0,
    MITMobiusMachineTypes,
};

@interface MITMobiusResourceDataSource : NSObject
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

+ (NSURL*)defaultServerURL;
- (instancetype)init;
- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;
- (void)getObjectsForRoute:(MITMobiusRequestType)type completion:(void(^)(NSArray* objects, NSError *error))block;
- (NSDictionary*)resourcesGroupedByKey:(NSString*)key withManagedObjectContext:(NSManagedObjectContext*)context;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end
