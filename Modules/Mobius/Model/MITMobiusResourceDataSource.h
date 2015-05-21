#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITMobiusQuickSearchType) {
    MITMobiusQuickSearchRoomSet = 0,
    MITMobiusQuickSearchResourceType,
};

typedef NS_ENUM(NSInteger, MITMobiusResourceSearchType) {
    MITMobiusResourceSearchTypeAll = 0,
    MITMobiusResourceSearchTypeQuery,
    MITMobiusResourceSearchTypeComplexQuery,
    MITMobiusResourceSearchTypeCustomField
};

@class MITMobiusRecentSearchQuery;

@interface MITMobiusResourceDataSource : NSObject
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly) MITMobiusResourceSearchType queryType;
@property (nonatomic,strong) MITMobiusRecentSearchQuery *query;
@property (nonatomic,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext NS_DESIGNATED_INITIALIZER;

- (void)setCustomField:(NSString*)field withValue:(NSString*)value;
- (void)clearCustomField;
- (void)getResources:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))completion;

- (void)resourcesWithField:(NSString*)field value:(NSString*)value completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;
- (void)resourcesWithQueryObject:(MITMobiusRecentSearchQuery*)queryObject completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;
- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block;

- (void)getObjectsForRoute:(MITMobiusQuickSearchType)type completion:(void(^)(NSArray* objects, NSError *error))block;
- (NSDictionary*)resourcesGroupedByKey:(NSString*)key withManagedObjectContext:(NSManagedObjectContext*)context;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end
