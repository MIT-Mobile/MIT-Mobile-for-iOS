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

- (NSString *) locationString {
    NSMutableString *locationString = [NSMutableString string];
    NSString *roomNumber = self.roomNumber;
    if (roomNumber) {
        [locationString appendString:roomNumber];
    }
    NSString *locationDescription = self.locationDescription;
    if (locationDescription) {
        if (locationString.length > 0) {
            [locationString appendString:@"\n"];
        }
        
        [locationString appendString:locationDescription];
    }
    return locationString;
}

@end
