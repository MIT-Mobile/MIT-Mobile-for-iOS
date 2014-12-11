#import "MITCalendarsLocation.h"
#import "MITCalendarsEvent.h"

@implementation MITCalendarsLocation

@dynamic events;
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

- (NSString *)buildingNumberOrBestDescription
{
    NSString *buildingNumber;
    NSString *roomNumber = self.roomNumber;
    if (roomNumber) {
        NSArray *roomComponents = [roomNumber componentsSeparatedByString:@"-"];
        NSString *firstComponent = roomComponents.firstObject;
        if (firstComponent.length == 1 && firstComponent.intValue == 0) {
            // First component is a letter.  Someone probably put N-51 or E-15 instead of N51 or E15
            if (roomComponents.count >= 2) {
                NSString *secondComponent = roomComponents[1];
                if (secondComponent.intValue > 0) {
                    buildingNumber = [NSString stringWithFormat:@"%@%@", firstComponent, secondComponent];
                }
            } else {
                NSLog(@"This Room Is Broken for Events: %@ Location : %@", [[self.events valueForKey:@"title"] componentsJoinedByString:@", "], self);
                buildingNumber = roomNumber;
            }
        } else {
            buildingNumber = firstComponent;
        }
    } else {
        buildingNumber = self.locationDescription;
    }
    
    // Removing leading whitespace
    while ([buildingNumber hasPrefix:@" "]) {
        buildingNumber = [buildingNumber substringFromIndex:1];
    }
    
    buildingNumber = [buildingNumber stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    return buildingNumber;
}

@end