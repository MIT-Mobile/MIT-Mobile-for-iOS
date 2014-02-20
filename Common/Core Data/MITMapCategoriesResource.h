#import "MITMobileManagedResource.h"

@interface MITMapCategoriesResource : MITMobileManagedResource
+ (NSFetchRequest*)categories:(MITMobileManagedResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
