#import "MITMobiusCategory.h"
#import "MITMobiusResource.h"
#import "MITMobiusType.h"


@implementation MITMobiusCategory

@dynamic identifier;
@dynamic name;
@dynamic resources;
@dynamic types;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"category" : @"name"};
    
    [mapping addAttributeMappingsFromDictionary:mappings];

    return mapping;
}

@end
