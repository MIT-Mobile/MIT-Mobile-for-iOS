#import "MITMobileResources.h"
#import "MITMobile.h"

@interface MITPersonResource : MITMobileManagedResource

+ (void) personWithID:(NSString *)uid loaded:(MITMobileResult)block;
+ (void) peopleMatchingQuery:(NSString *)query loaded:(MITMobileResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
