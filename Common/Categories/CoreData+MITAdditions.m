#import "CoreData+MITAdditions.h"
#import "MITAdditions.h"

@implementation NSManagedObjectContext (MITAdditions)
+ objectIDsForManagedObjects:(NSArray*)objects
{
    return [objects mapObjectsUsingBlock:^NSManagedObjectID* (id object, NSUInteger idx) {
        if ([object isKindOfClass:[NSManagedObjectID class]]) {
            return object;
        } else if ([object isKindOfClass:[NSManagedObject class]]) {
            return [object objectID];
        } else {
            return nil;
        }
    }];
}

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
    NSArray *objectIDs = [NSManagedObjectContext objectIDsForManagedObjects:objects];
    return [self objectsWithIDs:objectIDs];
}
@end
