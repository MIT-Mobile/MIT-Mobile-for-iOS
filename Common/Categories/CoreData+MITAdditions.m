#import "CoreData+MITAdditions.h"

FOUNDATION_EXPORT NSArray* NSManagedObjectIDsFromNSManagedObjects(NSArray *objects)
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
    return [self objectsWithIDs:objectIDs class:nil];
}

- (NSArray*)objectsWithIDs:(NSArray*)objectIDs class:(Class)objectClass
{
    NSMutableArray *resolvedObjects = nil;
    if(objectIDs) {
        resolvedObjects = [[NSMutableArray alloc] init];
        [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
            NSManagedObject *object = [self objectWithID:objectID];

            if (objectClass) {
                if ([object isKindOfClass:objectClass]) {
                    [resolvedObjects addObject:object];
                } else {
                    NSString *errorString = [[NSString alloc] initWithFormat:@"Object with id %@ at index %lu is kind of '%@', expected '%@'",
                                             objectID, (long unsigned)idx, NSStringFromClass([object class]),NSStringFromClass(objectClass)];

                    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:errorString
                                                 userInfo:nil];
                }
            } else {
                [resolvedObjects addObject:object];
            }
        }];
    }

    return resolvedObjects;
}
@end
