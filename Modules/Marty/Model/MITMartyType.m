#import "MITMartyType.h"
#import "MITMartyCategory.h"
#import "MITMartyResource.h"
#import "MITMartyTemplate.h"


@implementation MITMartyType

@dynamic category;
@dynamic resources;
@dynamic template;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"type" : @"name",
                               @"created_by" : @"createdBy",
                               @"date_created" : @"created",
                               @"modified_by" : @"modifiedBy",
                               @"date_modified" : @"modified",
                               @"_id" : @"identifier"};

    [mapping addAttributeMappingsFromDictionary:mappings];

    NSRelationshipDescription *categoryRelationship = [[self entityDescription] relationshipsByName][@"category"];
    RKConnectionDescription *categoryConnection = [[RKConnectionDescription alloc] initWithRelationship:categoryRelationship attributes:@{@"categoryIdentifier": @"identifier"}];
    [mapping addConnection:categoryConnection];

    mapping.assignsNilForMissingRelationships = YES;

    return mapping;
}

@end
