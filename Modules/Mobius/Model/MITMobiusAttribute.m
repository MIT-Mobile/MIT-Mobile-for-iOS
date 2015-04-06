#import "MITMobiusAttribute.h"
#import "MITMobiusAttributeValueSet.h"
#import "MITMobiusResource.h"
#import "MITMobiusAttributeValue.h"


@implementation MITMobiusAttribute

@dynamic fieldType;
@dynamic identifier;
@dynamic label;
@dynamic widgetType;
@dynamic resources;
@dynamic valueSet;
@dynamic values;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    mapping.assignsNilForMissingRelationships = YES;

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"field_type" : @"fieldType",
                               @"widget_type" : @"widgetType",
                               @"label" : @"label"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_valueSet" toKeyPath:@"valueSet" withMapping:[MITMobiusAttributeValueSet objectMapping]];
    [mapping addPropertyMapping:valuesMapping];

    NSRelationshipDescription *attributeRelationship = [[self entityDescription] relationshipsByName][@"attribute"];
    RKConnectionDescription *attributeConnection = [[RKConnectionDescription alloc] initWithRelationship:attributeRelationship attributes:@{@"templateAttributeIdentifier": @"identifier"}];
    [mapping addConnection:attributeConnection];

    return mapping;
}

@end
