#import "MITCalendarsResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITCalendarsCalendar.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarsLocation.h"
#import "MITCalendarsContact.h"
#import "MITCalendarsSponsor.h"
#import "MITCalendarsSeriesInfo.h"

@implementation MITCalendarsCalendarsResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITCalendarsResourceName pathPattern:MITCalendarsPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITCalendarsCalendar objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITCalendarsCalendarResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITCalendarResourceName pathPattern:MITCalendarPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITCalendarsCalendar objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITCalendarsEventsResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITCalendarEventsResourceName pathPattern:MITCalendarEventsPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITCalendarsEvent objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequestForURL:(NSURL *)url
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[url relativePath] stringByAppendingString:@"/"]];
    
    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
    
    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITCalendarsEvent entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        return fetchRequest;
    }
    return nil;
}

@end

@implementation MITCalendarsEventResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITCalendarEventResourceName pathPattern:MITCalendarEventPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITCalendarsEvent objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end