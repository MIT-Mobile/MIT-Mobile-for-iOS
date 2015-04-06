#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusResource.h"
#import "MITMobiusResourceAttributeValue.h"
#import "MITMobiusAttribute.h"


@implementation MITMobiusResourceAttributeValueSet

@dynamic attributeIdentifier;
@dynamic values;
@dynamic label;
@dynamic resource;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *valueSetMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [valueSetMapping addAttributeMappingsFromDictionary:@{@"_attribute._id" : @"attributeIdentifier",
                                                          @"_attribute.label" : @"label"}];

    RKEntityMapping *valueMapping = [[RKEntityMapping alloc] initWithEntity:[MITMobiusResourceAttributeValue entityDescription]];
    RKAttributeMapping *valueAttributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"value"];
    [valueMapping addPropertyMapping:valueAttributeMapping];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"value" toKeyPath:@"values" withMapping:valueMapping];
    [valueSetMapping addPropertyMapping:valuesMapping];

    return valueSetMapping;
}


@end
