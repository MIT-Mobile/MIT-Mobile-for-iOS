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

- (NSOrderedSet *)house
{
    [self willAccessValueForKey:@"house"];
    NSOrderedSet *house = [self primitiveValueForKey:@"house"];
    [self didAccessValueForKey:@"house"];
    
    NSArray *array = [house sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *first = [(MITDiningHouseVenue*)obj1 shortName];
        NSString *second = [(MITDiningHouseVenue*)obj2 shortName];
        return [first compare:second];
    }];
    
    return [NSOrderedSet orderedSetWithArray:array];
}

@end
