#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningLocation.h"

@implementation MITDiningHouseVenue

@dynamic iconURL;
@dynamic identifier;
@dynamic name;
@dynamic payment;
@dynamic shortName;
@dynamic location;
@dynamic mealsByDay;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_name" : @"shortName",
                                                  @"icon_url" : @"iconURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"payment"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:[MITDiningLocation objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"meals_by_day" toKeyPath:@"mealsByDay" withMapping:[MITDiningHouseDay objectMapping]]];

    [mapping setIdentificationAttributes:@[@"identifier"]];
    
    return mapping;
}

@end
