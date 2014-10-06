#import "MITDiningVenues.h"
#import "MITDiningDining.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningRetailVenue.h"


@implementation MITDiningVenues

@dynamic dining;
@dynamic house;
@dynamic retail;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"house" toKeyPath:@"house" withMapping:[MITDiningHouseVenue objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"retail" toKeyPath:@"retail" withMapping:[MITDiningRetailVenue objectMapping]]];
    
    return mapping;
}

@end
