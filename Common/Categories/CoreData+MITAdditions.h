#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (MITAdditions)
+ objectIDsForManagedObjects:(NSArray*)objects;
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs;
- (NSArray*)transferManagedObjects:(NSArray*)objects;
@end