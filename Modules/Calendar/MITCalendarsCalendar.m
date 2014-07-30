#import "MITCalendarsCalendar.h"
#import "MITCalendarsCalendar.h"


@implementation MITCalendarsCalendar

@dynamic identifier;
@dynamic url;
@dynamic eventsUrl;
@dynamic name;
@dynamic shortName;
@dynamic categories;
@dynamic parentCategory;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"events_url" : @"eventsUrl",
                                                  @"short_name"  : @"shortName"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"name"]];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"categories" toKeyPath:@"parentCategory" withMapping:[MITCalendarsCalendar objectMapping]]];
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

@end
