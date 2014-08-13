#import "MITDiningMeal.h"
#import "MITDiningMenuItem.h"


@implementation MITDiningMeal

@dynamic endTime;
@dynamic message;
@dynamic name;
@dynamic startTime;
@dynamic items;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"start_time" : @"startTime",
                                                  @"end_time" : @"endTime"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"items" toKeyPath:@"items" withMapping:[MITDiningMenuItem objectMapping]]];
    
    return mapping;
}

@end
