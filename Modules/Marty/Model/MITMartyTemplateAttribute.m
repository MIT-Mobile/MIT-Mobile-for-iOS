#import "MITMartyTemplateAttribute.h"
#import "MITMobiusResourceAttribute.h"
#import "MITMartyTemplate.h"

@implementation MITMartyTemplateAttribute

@dynamic fieldType;
@dynamic identifier;
@dynamic label;
@dynamic required;
@dynamic sort;
@dynamic widgetType;
@dynamic attributeValues;
@dynamic template;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"label" : @"label",
                               @"required" : @"required",
                               @"sort" : @"sort",
                               @"widget_type" : @"widgetType"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    mapping.assignsNilForMissingRelationships = YES;

    return mapping;
}

@end
