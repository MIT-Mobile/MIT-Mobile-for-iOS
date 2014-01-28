#import "MITMobileManagedResource.h"

@interface MITMapPlacesResource : MITMobileManagedResource
+ (void)placesWithQuery:(NSString*)queryString loaded:(MITMobileResult)block;
+ (NSFetchRequest*)placesInCategory:(NSString*)categoryID loaded:(MITMobileManagedResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
