#import "MITMobileResources.h"
#import "MITMobile.h"

@class MITNewsStory;
@class MITNewsCategory;

@interface MITNewsStoriesResource : MITMobileManagedResource
+ (void)storiesForQuery:(NSString*)queryString limit:(NSUInteger)limit loaded:(MITMobileResult)block;
+ (NSFetchRequest*)storiesInCategory:(NSString*)categoryID limit:(NSUInteger)limit loaded:(MITMobileManagedResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
