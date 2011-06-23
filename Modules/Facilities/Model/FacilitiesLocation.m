#import "FacilitiesLocation.h"
#import "FacilitiesContent.h"


@implementation FacilitiesLocation
@dynamic number;
@dynamic uid;
@dynamic longitude;
@dynamic latitude;
@dynamic roomsUpdated;
@dynamic name;
@dynamic categories;
@dynamic contents;

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


- (void)addContentsObject:(FacilitiesContents *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contents"] addObject:value];
    [self didChangeValueForKey:@"contents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContentsObject:(FacilitiesContents *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contents"] removeObject:value];
    [self didChangeValueForKey:@"contents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContents:(NSSet *)value {    
    [self willChangeValueForKey:@"contents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contents"] unionSet:value];
    [self didChangeValueForKey:@"contents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContents:(NSSet *)value {
    [self willChangeValueForKey:@"contents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contents"] minusSet:value];
    [self didChangeValueForKey:@"contents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (NSString*)displayString {
    NSString *string = nil;
    
    if (([self.number length] > 0) && ([self.number isEqualToString:self.name] == NO)) {
        string = [NSString stringWithFormat:@"%@ - %@", self.number, self.name];
    } else {
        string = [NSString stringWithString:self.name];
    }
    
    return string;
}
@end
