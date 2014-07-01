#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITNewsCategory;
@class MITNewsStory;

@interface MITNewsDataSource : NSObject
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) NSOrderedSet *categories;
@property (nonatomic,readonly,strong) NSOrderedSet *stories;

+ (void)clearCachedObjects;

+ (instancetype)allCategoriesDataSource;
+ (instancetype)featuredStoriesDataSource;
+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category;
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (BOOL)hasNextPage;
- (void)nextPage:(void(^)(NSError *error))block;
- (void)refresh:(void(^)(NSError *error))block;
@end
