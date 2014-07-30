#import "MITCalendarsResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITCalendarsCalendar.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarsLocation.h"
#import "MITCalendarsContact.h"
#import "MITCalendarsSponsor.h"
#import "MITCalendarsSeriesInfo.h"

@implementation MITCalendarsResource

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

@implementation MITCalendarResource

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

@implementation MITEventsResource

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

@end

@implementation MITEventResource

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