#import "LibrariesLocationsHours.h"
#import "LibrariesLocationsHoursTerm.h"
#import "LibrariesLocationsHoursTermHours.h"
#import "CoreDataManager.h"

#define LibrariesLocationsHoursEntity @"LibrariesLocationsHours"
#define LibrariesLocationsHoursTermEntity @"LibrariesLocationsHoursTerm"
#define LibrariesLocationsHoursTermHoursEntity @"LibrariesLocationsHoursTermHours"

@interface LibrariesLocationsHours ()
- (void)addTermWithDict:(NSDictionary *)dict sortOrder:(NSInteger)sortOrder;
@end

@implementation LibrariesLocationsHours
@dynamic title;
@dynamic status;
@dynamic hoursToday;
@dynamic url;
@dynamic telephone;
@dynamic location;
@dynamic terms;

- (void)addTermsObject:(LibrariesLocationsHoursTerm *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"terms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"terms"] addObject:value];
    [self didChangeValueForKey:@"terms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
}

- (void)removeTermsObject:(LibrariesLocationsHoursTerm *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"terms"] removeObject:value];
    [self didChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
}

- (void)addTerms:(NSSet *)value {    
    [self willChangeValueForKey:@"terms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"terms"] unionSet:value];
    [self didChangeValueForKey:@"terms" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeTerms:(NSSet *)value {
    [self willChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"terms"] minusSet:value];
    [self didChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (BOOL)hasDetails {
    return (self.hoursToday != nil);
}

- (void)updateDetailsWithDict:(NSDictionary *)dict {
    self.hoursToday = dict[@"hours_today"];
    self.url = dict[@"url"];
    self.telephone = dict[@"tel"];
    self.location = dict[@"location"];
    
    NSDictionary *termSchedules = dict[@"schedule"];
    if (termSchedules[@"current_term"]) {
        [self addTermWithDict:termSchedules[@"current_term"]
                    sortOrder:0];
    }
    
    [termSchedules[@"next_terms"] enumerateObjectsUsingBlock:^(NSDictionary *term, NSUInteger idx, BOOL *stop) {
        [self addTermWithDict:term
                    sortOrder:(idx + 1)];
    }];
    
    [termSchedules[@"previous_terms"] enumerateObjectsUsingBlock:^(NSDictionary *term, NSUInteger idx, BOOL *stop) {
        [self addTermWithDict:term
                    sortOrder:-(idx + 1)];
    }];
}

- (void)addTermWithDict:(NSDictionary *)dict sortOrder:(NSInteger)sortOrder {
    LibrariesLocationsHoursTerm *termObject = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursTermEntity];
    NSDictionary *rangeDict = dict[@"range"];
    NSTimeInterval startTimestamp = [rangeDict[@"start"] doubleValue];
    NSTimeInterval endTimestamp = [rangeDict[@"end"] doubleValue];
    
    termObject.startDate = [NSDate dateWithTimeIntervalSince1970:startTimestamp];
    termObject.endDate = [NSDate dateWithTimeIntervalSince1970:endTimestamp];
    termObject.termSortOrder = @(sortOrder);
    termObject.name = dict[@"name"];
    
    NSArray *termHoursData = dict[@"hours"];
    NSMutableSet *termHours = [NSMutableSet set];
    [termHoursData enumerateObjectsUsingBlock:^(NSDictionary *hoursData, NSUInteger idx, BOOL *stop) {
        LibrariesLocationsHoursTermHours *hoursObject = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursTermHoursEntity];
        hoursObject.title = hoursData[@"title"];
        hoursObject.hoursDescription = hoursData[@"description"];
        hoursObject.sortOrder = @(idx);
        [termHours addObject:hoursObject];
    }];
    
    termObject.hours = termHours;
    [self addTermsObject:termObject];
}

+ (void)removeAllLibraries {
    [[CoreDataManager coreDataManager] deleteObjectsForEntity:LibrariesLocationsHoursEntity];
}

+ (LibrariesLocationsHours *)libraryWithDict:(NSDictionary *)dict {
    LibrariesLocationsHours *library = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursEntity];
    library.title = dict[@"library"];
    library.status = dict[@"status"];
    return library;
}

@end
