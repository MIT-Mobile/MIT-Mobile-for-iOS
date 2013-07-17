#import "VenueLocation.h"
#import "HouseVenue.h"
#import "CoreDataManager.h"
#import "CoreLocation+MITAdditions.h"

@implementation VenueLocation

@dynamic roomNumber;
@dynamic city;
@dynamic street;
@dynamic latitude;
@dynamic longitude;
@dynamic displayDescription;
@dynamic zipcode;
@dynamic state;
@dynamic houseVenue;
@dynamic retailVenue;

+ (VenueLocation *)newLocationWithDictionary:(NSDictionary *)dict {
    VenueLocation *location = [CoreDataManager insertNewObjectForEntityForName:@"VenueLocation"];
    
    location.latitude = dict[@"latitude"];
    location.longitude = dict[@"longitude"];
    location.roomNumber = dict[@"mit_room_number"];
    location.displayDescription = dict[@"description"];
    location.city = dict[@"city"];
    location.street = dict[@"street"];
    location.state = dict[@"state"];
    location.zipcode = dict[@"zipcode"];
    
    return location;
}

- (NSString*)locationDisplayString
{
    if ([self.displayDescription length]) {
        return self.displayDescription;
    } else if ([self.roomNumber length]) {
        return self.roomNumber;
    } else {
        NSMutableString *displayString = [[NSMutableString alloc] init];
        
        if ([self.street length]) {
            [displayString appendString:self.street];
        }
        
        if ([self.city length]) {
            if ([displayString length]) {
                [displayString appendFormat:@"\n%@", self.city];
            } else {
                [displayString appendString:self.city];
            }
        }
        
        if ([displayString length]) {
            if (self.state) {
                [displayString appendFormat:@", %@",self.state];
            }
        } else {
            displayString = nil;
        }
        
        return displayString;
    }
}

@end
