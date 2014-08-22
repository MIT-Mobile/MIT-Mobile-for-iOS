#import "MITNewsDataSource.h"

@interface MITNewsStoriesDataSource : MITNewsDataSource
@property (nonatomic,readonly,strong) NSOrderedSet *stories;
@property (readonly,strong) NSDate *refreshedAt;

+ (instancetype)featuredStoriesDataSource;
+ (instancetype)dataSourceForQuery:(NSString*)query;
+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category;

@end
