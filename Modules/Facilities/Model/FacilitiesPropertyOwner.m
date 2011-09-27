#import "FacilitiesPropertyOwner.h"
#import "FacilitiesLocation.h"


@implementation FacilitiesPropertyOwner
@dynamic name;
@dynamic phone;
@dynamic email;
@dynamic locations;

- (void)addLocationsObject:(FacilitiesLocation *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"locations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"locations"] addObject:value];
    [self didChangeValueForKey:@"locations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeLocationsObject:(FacilitiesLocation *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"locations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"locations"] removeObject:value];
    [self didChangeValueForKey:@"locations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addLocations:(NSSet *)value {    
    [self willChangeValueForKey:@"locations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"locations"] unionSet:value];
    [self didChangeValueForKey:@"locations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeLocations:(NSSet *)value {
    [self willChangeValueForKey:@"locations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"locations"] minusSet:value];
    [self didChangeValueForKey:@"locations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
