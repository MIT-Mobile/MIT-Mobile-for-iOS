#import "MITMobileManagedResource.h"

@interface MITNewsCategoriesResource : MITMobileManagedResource
+ (NSFetchRequest*)categories:(MITMobileManagedResult)block;
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;
@end
