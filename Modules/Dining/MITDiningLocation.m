#import "MITDiningLocation.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningRetailVenue.h"

@implementation MITDiningLocation

@dynamic city;
@dynamic latitude;
@dynamic locationDescription;
@dynamic longitude;
@dynamic mitRoomNumber;
@dynamic state;
@dynamic street;
@dynamic zipCode;
@dynamic houseVenue;
@dynamic retailVenue;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"mit_room_number" : @"mitRoomNumber",
                                                  @"description" : @"locationDescription",
                                                  @"zip_code" : @"zipCode"}];
    
    [mapping addAttributeMappingsFromArray:@[@"latitude", @"longitude", @"street", @"city", @"state"]];
   
    mapping.assignsNilForMissingRelationships = YES;
    mapping.assignsDefaultValueForMissingAttributes = YES;
    
    return mapping;
}

#pragma mark - Convenience Methods

- (NSString *)locationDisplayString
{
    NSString *locationDisplayString = nil;
    if (self.locationDescription.length > 0) {
        locationDisplayString = self.locationDescription;
    } else if (self.mitRoomNumber.length > 0) {
        locationDisplayString = self.mitRoomNumber;
    } else {
        NSMutableString *addressString = [NSMutableString string];
        NSString *street = self.street.length > 0 ? self.street : nil;
        NSString *city = self.city.length > 0 ? self.city : nil;
        NSString *state = self.state.length > 0 ? self.state : nil;
        
        if (street) {
            [addressString appendString:street];
        }
        if (city) {
            if (street) {
                [addressString appendString:@"\n"];
            }
            [addressString appendString:city];
        }
        
        if (addressString.length > 0) {
            if (state) {
                [addressString appendFormat:@", %@", state];
            }
        } else {
            addressString = nil;
        }
        
        locationDisplayString = addressString;
    }
    return locationDisplayString;
}


@end
