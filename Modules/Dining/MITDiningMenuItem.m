#import "MITDiningMenuItem.h"


@implementation MITDiningMenuItem

@dynamic dietaryFlags;
@dynamic itemDescription;
@dynamic name;
@dynamic station;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"station", @"name"]];
    [mapping addAttributeMappingsFromDictionary:@{@"description" : @"itemDescription",
                                                  @"dietary_flags" : @"dietaryFlags"}];
     
    
    return mapping;
}

@end
