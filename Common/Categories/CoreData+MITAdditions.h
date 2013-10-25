#import <CoreData/CoreData.h>

FOUNDATION_EXPORT NSArray* NSManagedObjectIDsForNSManagedObjects(NSArray *objects);

@interface NSManagedObjectContext (MITAdditions)
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs;
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs class:(Class)objectClass;
@end