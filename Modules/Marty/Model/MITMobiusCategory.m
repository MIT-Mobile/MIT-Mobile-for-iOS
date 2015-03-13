#import "MITMobiusCategory.h"
#import "MITMobiusResource.h"
#import "MITMobiusTemplate.h"
#import "MITMobiusType.h"


@implementation MITMobiusCategory

@dynamic resources;
@dynamic template;
@dynamic types;
@dynamic templateIdentifier;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"_template" : @"templateIdentifier",
                               @"category" : @"name",
                               @"created_by" : @"createdBy",
                               @"date_created" : @"created",
                               @"modified_by" : @"modifiedBy",
                               @"date_modified" : @"modified"};
    [mapping addAttributeMappingsFromDictionary:mappings];

    NSRelationshipDescription *templateRelationship = [[self entityDescription] relationshipsByName][@"template"];
    RKConnectionDescription *templateConnection = [[RKConnectionDescription alloc] initWithRelationship:templateRelationship attributes:@{@"templateIdentifier": @"identifier"}];
    [mapping addConnection:templateConnection];

    return mapping;
}

@end
