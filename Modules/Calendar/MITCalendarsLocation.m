#import "MITCalendarsLocation.h"


@implementation MITCalendarsLocation

@dynamic locationDescription;
@dynamic roomNumber;
@dynamic coordinates;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"room_number": @"roomNumber",
                                                  @"description" : @"locationDescription"}];
    [mapping addAttributeMappingsFromArray:@[@"coordinates"]];

    [mapping setIdentificationAttributes:@[@"roomNumber", @"locationDescription"]];
    return mapping;
}

@end
