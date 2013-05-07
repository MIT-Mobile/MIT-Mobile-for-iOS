#import "VenueLocation.h"
#import "HouseVenue.h"
#import "CoreDataManager.h"

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


@end
