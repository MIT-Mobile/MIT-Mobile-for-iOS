#import "MITMobileManagedResource.h"

@class MITNewsStory;
@class MITNewsCategory;

@interface MITNewsStoriesResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
