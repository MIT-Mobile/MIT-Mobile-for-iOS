#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusResource.h"
#import "MITMobiusResourceAttributeValue.h"
#import "MITMobiusAttribute.h"


@implementation MITMobiusResourceAttributeValueSet

@dynamic values;
@dynamic attribute;
@dynamic resource;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *valueSetMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    RKRelationshipMapping *attributeMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_attribute" toKeyPath:@"attribute" withMapping:[MITMobiusAttribute objectMapping]];
    [valueSetMapping addPropertyMapping:attributeMapping];

    RKEntityMapping *valueMapping = [[RKEntityMapping alloc] initWithEntity:[MITMobiusResourceAttributeValue entityDescription]];
    RKAttributeMapping *valueAttributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"value"];
    [valueMapping addPropertyMapping:valueAttributeMapping];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"value" toKeyPath:@"values" withMapping:valueMapping];
    [valueSetMapping addPropertyMapping:valuesMapping];

    return valueSetMapping;
}


@end
