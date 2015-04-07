#import "MITMobiusAttribute.h"
#import "MITMobiusResource.h"
#import "MITMobiusAttributeValue.h"


@implementation MITMobiusAttribute

@dynamic fieldType;
@dynamic identifier;
@dynamic label;
@dynamic widgetType;
@dynamic resources;
@dynamic valueSetName;
@dynamic values;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"field_type" : @"fieldType",
                               @"widget_type" : @"widgetType",
                               @"label" : @"label",
                               @"_valueSet.value_set" : @"valueSetName"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_valueSet.values" toKeyPath:@"values" withMapping:[MITMobiusAttributeValue objectMapping]];
    [mapping addPropertyMapping:valuesMapping];

    return mapping;
}

@end
