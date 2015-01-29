#import "MITPersonResource.h"

@interface MITPeopleResource : MITPersonResource

+ (void) peopleMatchingQuery:(NSString *)query loaded:(MITMobileResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
