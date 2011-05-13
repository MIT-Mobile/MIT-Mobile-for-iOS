//
//  FacilitiesLocation.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/11/11.
//  Copyright (c) 2011 MIT. All rights reserved.
//

#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"


@implementation FacilitiesLocation
@dynamic latitude;
@dynamic number;
@dynamic uid;
@dynamic name;
@dynamic longitude;
@dynamic categories;
@dynamic rooms;

- (void)addCategoriesObject:(NSManagedObject *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] addObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCategoriesObject:(NSManagedObject *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"categories"] removeObject:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addCategories:(NSSet *)value {    
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] unionSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeCategories:(NSSet *)value {
    [self willChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"categories"] minusSet:value];
    [self didChangeValueForKey:@"categories" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addRoomsObject:(FacilitiesRoom *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"rooms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"rooms"] addObject:value];
    [self didChangeValueForKey:@"rooms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeRoomsObject:(FacilitiesRoom *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"rooms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"rooms"] removeObject:value];
    [self didChangeValueForKey:@"rooms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addRooms:(NSSet *)value {    
    [self willChangeValueForKey:@"rooms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"rooms"] unionSet:value];
    [self didChangeValueForKey:@"rooms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeRooms:(NSSet *)value {
    [self willChangeValueForKey:@"rooms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"rooms"] minusSet:value];
    [self didChangeValueForKey:@"rooms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
