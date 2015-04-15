#import "MITMobiusAttribute.h"
#import "MITMobiusResource.h"
#import "MITMobiusAttributeValue.h"


@implementation MITMobiusAttribute

@dynamic fieldType;
@dynamic identifier;
@dynamic label;
@dynamic valueSetName;
@dynamic widgetType;
@dynamic values;
@dynamic searchOptions;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"field_type" : @"fieldType",
                               @"widget_type" : @"widgetType",
                               @"label" : @"label",
                               @"_valueset.value_set" : @"valueSetName"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_valueset.values" toKeyPath:@"values" withMapping:[MITMobiusAttributeValue objectMapping]];
    [mapping addPropertyMapping:valuesMapping];

    return mapping;
}

- (MITMobiusAttributeType)type
{
    if ([self.widgetType isEqualToString:@"text_area"]) {
        return MITMobiusAttributeTypeText;
    } else if ([self.widgetType isEqualToString:@"text_field"]) {
        if ([self.fieldType isEqualToString:@"number"]) {
            return MITMobiusAttributeTypeNumeric;
        } else if ([self.fieldType isEqualToString:@"text"]) {
            return MITMobiusAttributeTypeString;
        }
    } else if ([self.widgetType isEqualToString:@"autocomplete"]) {
        return MITMobiusAttributeTypeAutocompletion;
    } else if ([self.widgetType isEqualToString:@"checkbox"]) {
        return MITMobiusAttributeTypeOptionMultiple;
    } else if ([self.widgetType isEqualToString:@"select"]) {
        return MITMobiusAttributeTypeOptionSingle;
    } else if ([self.widgetType isEqualToString:@"radio"]) {
        return MITMobiusAttributeTypeOptionSingle;
    }

    NSString *reason = [NSString stringWithFormat:@"{%@:%@}",self.widgetType,self.fieldType];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

@end
