#import "MITNewsDataSource.h"

@interface MITNewsStoriesDataSource : MITNewsDataSource
@property (nonatomic,readonly,copy) NSString *query;
@property (nonatomic,readonly,copy) NSString *category;
@property (nonatomic,readonly) BOOL isFeaturedStorySource;

@property (nonatomic,readonly,strong) NSOrderedSet *stories;

+ (instancetype)featuredStoriesDataSource;
+ (instancetype)dataSourceForQuery:(NSString*)query;
+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category;

@end
