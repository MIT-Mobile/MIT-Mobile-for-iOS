//
//  MITCalendarsCalendar.m
//  MIT Mobile
//
//  Created by Samuel Voigt on 7/31/14.
//
//

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

@end
