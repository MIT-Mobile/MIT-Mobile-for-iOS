//
//  MITMobiusResourceAttribute.m
//  MIT Mobile
//
//  Created by Blake Skinner on 1/29/15.
//
//

#import "MITMobiusResourceAttribute.h"
#import "MITMobiusResourceAttributeValue.h"
#import "MITMobiusTemplateAttribute.h"

@implementation MITMobiusResourceAttribute

@dynamic templateAttributeIdentifier;
@dynamic identifier;
@dynamic attribute;
@dynamic values;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"_attribute" : @"templateAttributeIdentifier"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *valuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"value" toKeyPath:@"values" withMapping:[MITMobiusResourceAttributeValue objectMapping]];
    [mapping addPropertyMapping:valuesMapping];

    NSRelationshipDescription *attributeRelationship = [[self entityDescription] relationshipsByName][@"attribute"];
    RKConnectionDescription *attributeConnection = [[RKConnectionDescription alloc] initWithRelationship:attributeRelationship attributes:@{@"templateAttributeIdentifier": @"identifier"}];
    [mapping addConnection:attributeConnection];

    return mapping;
}

@end
