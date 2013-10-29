#import "CoreData+MITAdditions.h"

FOUNDATION_EXPORT NSArray* NSManagedObjectIDsForNSManagedObjects(NSArray *objects)
{
    NSMutableArray *objectIDs = nil;
    if(objects) {
        objectIDs = [[NSMutableArray alloc] init];
        for (NSManagedObject *object in objects) {
            [objectIDs addObject:[object objectID]];
        }
    }

    return objectIDs;
}

@implementation NSManagedObjectContext (MITAdditions)
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs
{
    NSMutableArray *resolvedObjects = nil;
    if(objectIDs) {
        resolvedObjects = [[NSMutableArray alloc] init];
        [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
            NSManagedObject *object = [self objectWithID:objectID];
            [resolvedObjects addObject:object];
        }];
    }

    return resolvedObjects;
}

- (NSArray*)transferManagedObjects:(NSArray*)objects
{
    NSArray *objectIDs = NSManagedObjectIDsForNSManagedObjects(objects);
    return [self objectsWithIDs:objectIDs];
}
@end
