#import "MITDiningLocation.h"


@implementation MITDiningLocation

@dynamic city;
@dynamic latitude;
@dynamic locationDescription;
@dynamic longitude;
@dynamic mitRoomNumber;
@dynamic state;
@dynamic street;
@dynamic zipCode;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"mit_room_number" : @"mitRoomNumber",
                                                  @"description" : @"locationDescription",
                                                  @"zip_code" : @"zipCode"}];
    
    [mapping addAttributeMappingsFromArray:@[@"latitude", @"longitude", @"street", @"city", @"state"]];
    
    return mapping;
}

@end
