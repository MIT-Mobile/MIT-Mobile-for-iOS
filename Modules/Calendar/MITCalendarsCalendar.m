#import "MITCalendarsCalendar.h"
#import "MITCalendarsCalendar.h"

@implementation MITCalendarsCalendar

@dynamic eventsUrl;
@dynamic identifier;
@dynamic name;
@dynamic shortName;
@dynamic url;
@dynamic categories;
@dynamic parentCategory;
@dynamic events;


- (BOOL)hasSubCategories
{
    return [self.categories count] > 0;
}

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"events_url" : @"eventsUrl",
                                                  @"short_name"  : @"shortName"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"name"]];
    
    [mapping setIdentificationAttributes:@[@"identifier"]];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"categories" toKeyPath:@"categories" withMapping:mapping]];
    
    return mapping;
}

- (BOOL)isEqualToCalendar:(MITCalendarsCalendar *)calendar
{
    return [self.identifier isEqualToString:calendar.identifier];
}

@end