#import "MITMobiusAttributeValueSet.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusAttributeValue.h"


@implementation MITMobiusAttributeValueSet

@dynamic name;
@dynamic values;
@dynamic attribute;

+ (RKEntityMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    mapping.assignsNilForMissingRelationships = YES;

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"value_set" : @"name"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"values" toKeyPath:@"values" withMapping:[MITMobiusAttributeValueSet objectMapping]];
    [mapping addPropertyMapping:valuesMapping];

    return mapping;
}
@end
