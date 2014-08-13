#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"

@implementation MITDiningHouseDay

@dynamic date;
@dynamic message;
@dynamic meals;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"date", @"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"meals" toKeyPath:@"meals" withMapping:[MITDiningMeal objectMapping]]];
    
    return mapping;
}

@end
