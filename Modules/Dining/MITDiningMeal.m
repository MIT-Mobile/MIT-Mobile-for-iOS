#import "MITDiningMeal.h"
#import "MITDiningMenuItem.h"
#import "MITAdditions.h"

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


- (NSString *)mealHoursDescription
{
    NSString *description = nil;
    if (!self.startTime || !self.endTime) {
        description = self.message;
    } else {
        NSString *startString = [self.startTime MITShortTimeOfDayString];
        NSString *endString = [self.endTime MITShortTimeOfDayString];
        
        description = [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    }
    return description;
}


@end
