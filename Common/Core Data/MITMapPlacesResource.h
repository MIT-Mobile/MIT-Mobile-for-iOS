#import "MITMobileResources.h"
#import "MITMobile.h"

@interface MITMapPlacesResource : MITMobileResource
- (instancetype)initWithPathPattern:(NSString*)pathPattern managedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
