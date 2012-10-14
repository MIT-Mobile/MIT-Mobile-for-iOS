#import "LibrariesLocationsHours.h"
#import "LibrariesLocationsHoursTerm.h"
#import "LibrariesLocationsHoursTermHours.h"
#import "CoreDataManager.h"

#define LibrariesLocationsHoursEntity @"LibrariesLocationsHours"
#define LibrariesLocationsHoursTermEntity @"LibrariesLocationsHoursTerm"
#define LibrariesLocationsHoursTermHoursEntity @"LibrariesLocationsHoursTermHours"

@interface LibrariesLocationsHours (Private)
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
    [changedObjects release];
}

- (void)removeTermsObject:(LibrariesLocationsHoursTerm *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"terms"] removeObject:value];
    [self didChangeValueForKey:@"terms" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
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
    self.hoursToday = [dict objectForKey:@"hours_today"];
    self.url = [dict objectForKey:@"url"];
    self.telephone = [dict objectForKey:@"tel"];
    self.location = [dict objectForKey:@"location"];
    
    NSDictionary *scheduleDict = [dict objectForKey:@"schedule"];
    if ([scheduleDict objectForKey:@"current_term"]) {
        [self addTermWithDict:[scheduleDict objectForKey:@"current_term"] sortOrder:0];
    }
    if ([scheduleDict objectForKey:@"next_terms"]) {
        NSArray *nextTerms = [scheduleDict objectForKey:@"next_terms"];
        for (NSInteger index=0; index < nextTerms.count; index++) {
            NSDictionary *term = [nextTerms objectAtIndex:index];
            [self addTermWithDict:term sortOrder:(index+1)]; 
        }
    }
    if ([scheduleDict objectForKey:@"previous_terms"]) {
        NSArray *previousTerms = [scheduleDict objectForKey:@"previous_terms"];
        for (NSInteger index=0; index < previousTerms.count; index++) {
            NSDictionary *term = [previousTerms objectAtIndex:index];
            [self addTermWithDict:term sortOrder:(-1 * (index+1))]; 
        }
    }
    
}

- (void)addTermWithDict:(NSDictionary *)dict sortOrder:(NSInteger)sortOrder {
    LibrariesLocationsHoursTerm *term = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursTermEntity];
    NSDictionary *rangeDict = [dict objectForKey:@"range"];
    NSNumber *startNumber = [rangeDict objectForKey:@"start"];
    term.startDate = [NSDate dateWithTimeIntervalSince1970:[startNumber longValue]];
    NSNumber *endNumber = [rangeDict objectForKey:@"end"];
    term.endDate = [NSDate dateWithTimeIntervalSince1970:[endNumber longValue]];
    term.termSortOrder = [NSNumber numberWithInteger:sortOrder];
    term.name = [dict objectForKey:@"name"];
    
    NSArray *hoursArray = [dict objectForKey:@"hours"];
    NSMutableSet *hoursSet = [NSMutableSet set];
    for (NSInteger index=0; index < hoursArray.count; index++) {
        LibrariesLocationsHoursTermHours *hours = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursTermHoursEntity];
        NSDictionary *hoursDict = [hoursArray objectAtIndex:index];
        hours.title = [hoursDict objectForKey:@"title"];
        hours.hoursDescription = [hoursDict objectForKey:@"description"];
        hours.sortOrder = [NSNumber numberWithInteger:index];
        [hoursSet addObject:hours];
    }
    term.hours = hoursSet;
    [self addTermsObject:term];
}

+ (void)removeAllLibraries {
    [[CoreDataManager coreDataManager] deleteObjectsForEntity:LibrariesLocationsHoursEntity];
}

+ (LibrariesLocationsHours *)libraryWithDict:(NSDictionary *)dict {
    LibrariesLocationsHours *library = [CoreDataManager insertNewObjectForEntityForName:LibrariesLocationsHoursEntity];
    library.title = [dict objectForKey:@"library"];
    library.status = [dict objectForKey:@"status"];
    return library;
}

@end
