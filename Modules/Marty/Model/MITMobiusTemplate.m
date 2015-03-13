#import "MITMobiusTemplate.h"
#import "MITMobiusCategory.h"
#import "MITMartyTemplateAttribute.h"
#import "MITMartyType.h"


@implementation MITMobiusTemplate

@dynamic descriptionText;
@dynamic attributes;
@dynamic categories;
@dynamic types;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"template_name" : @"name",
                               @"description" : @"descriptionText",
                               @"created_by" : @"createdBy",
                               @"date_created" : @"created",
                               @"modified_by" : @"modifiedBy",
                               @"date_modified" : @"modified"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    RKRelationshipMapping *attributesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"attributes" toKeyPath:@"attributes" withMapping:[MITMartyTemplateAttribute objectMapping]];
    [mapping addPropertyMapping:attributesMapping];

    mapping.assignsNilForMissingRelationships = YES;
    
    return mapping;
}

@end
