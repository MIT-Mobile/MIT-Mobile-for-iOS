#import "LibrariesLocationsHoursTerm.h"
#import "LibrariesLocationsHours.h"
#import "LibrariesLocationsHoursTermHours.h"


@implementation LibrariesLocationsHoursTerm
@dynamic startDate;
@dynamic endDate;
@dynamic name;
@dynamic termSortOrder;
@dynamic library;
@dynamic hours;


- (void)addHoursObject:(LibrariesLocationsHoursTermHours *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"hours" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"hours"] addObject:value];
    [self didChangeValueForKey:@"hours" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeHoursObject:(LibrariesLocationsHoursTermHours *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"hours" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"hours"] removeObject:value];
    [self didChangeValueForKey:@"hours" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addHours:(NSSet *)value {    
    [self willChangeValueForKey:@"hours" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"hours"] unionSet:value];
    [self didChangeValueForKey:@"hours" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeHours:(NSSet *)value {
    [self willChangeValueForKey:@"hours" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"hours"] minusSet:value];
    [self didChangeValueForKey:@"hours" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
