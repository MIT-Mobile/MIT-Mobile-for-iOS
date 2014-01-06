#import "MITMobileResources.h"
#import "MITMobile.h"

@class MITNewsStory;
@class MITNewsCategory;

@interface MITNewsStoriesResource : MITMobileManagedResource
+ (void)storiesForQuery:(NSString*)queryString afterStory:(NSString*)storyID limit:(NSUInteger)limit loaded:(MITMobileResult)block;
+ (NSFetchRequest*)storiesInCategory:(NSString*)categoryID afterStory:(NSString*)storyID limit:(NSUInteger)limit loaded:(MITMobileManagedResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
