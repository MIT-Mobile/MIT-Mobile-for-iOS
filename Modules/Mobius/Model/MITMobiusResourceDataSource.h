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
@class MITMobiusCustomQueryAttribute;

@interface MITMobiusResourceDataSource : NSObject
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSDate *lastFetched;
@property (nonatomic,readonly) MITMobiusResourceSearchType queryType;
@property (nonatomic,strong) MITMobiusRecentSearchQuery *query;
@property (nonatomic,copy) MITMobiusCustomQueryAttribute *customAttribute;
@property (nonatomic,copy) NSString *queryString;
@property (nonatomic,readonly,copy) NSArray *resources;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext NS_DESIGNATED_INITIALIZER;

- (void)getResources:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))completion;

- (void)getObjectsForRoute:(MITMobiusQuickSearchType)type completion:(void(^)(NSArray* objects, NSError *error))block;
- (NSDictionary*)resourcesGroupedByKey:(NSString*)key withManagedObjectContext:(NSManagedObjectContext*)context;

- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString;
- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)addError;
- (void)clearRecentSearches;

@end

@interface MITMobiusCustomQueryAttribute : NSObject
@property (nonatomic,readonly,copy) NSString *name;
@property (nonatomic,readonly,copy) NSString *identifier;
@property (nonatomic,readonly,copy) NSString *valueName;
@property (nonatomic,readonly,copy) NSString *valueIdentifier;

- (instancetype)init;
- (void)setAttributeIdentifier:(NSString*)identifier withName:(NSString*)name;
- (void)setValueIdentifier:(NSString*)identifier withName:(NSString*)name;
@end
