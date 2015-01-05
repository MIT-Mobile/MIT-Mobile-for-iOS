#import "MITMobileManagedResource.h"

@interface MITMapPlacesResource : MITMobileManagedResource

+ (void)placesWithQuery:(NSString*)queryString loaded:(MITMobileResult)block;
+ (NSFetchRequest*)placesInCategory:(NSString*)categoryID loaded:(MITMobileManagedResult)block;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end

@interface MITMapObjectResource : MITMapPlacesResource

+ (void)placesWithObjectID:(NSString *)objectID loaded:(MITMobileResult)block;
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

@end
