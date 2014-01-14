#import "MITMobileManagedResource.h"
#import "MITMobile.h"

@interface MITPersonResource : MITMobileManagedResource

+ (void) personWithID:(NSString *)uid loaded:(MITMobileResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
