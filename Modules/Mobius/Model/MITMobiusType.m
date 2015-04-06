#import "MITMobiusType.h"
#import "MITMobiusCategory.h"
#import "MITMobiusResource.h"


@implementation MITMobiusType

@dynamic identifier;
@dynamic name;
@dynamic categoryIdentifier;
@dynamic category;
@dynamic resources;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"_category" : @"categoryIdentifier",
                               @"type" : @"name"};

    [mapping addAttributeMappingsFromDictionary:mappings];

    NSRelationshipDescription *categoryRelationship = [[self entityDescription] relationshipsByName][@"category"];
    RKConnectionDescription *categoryConnection = [[RKConnectionDescription alloc] initWithRelationship:categoryRelationship attributes:@{@"categoryIdentifier": @"identifier"}];
    [mapping addConnection:categoryConnection];

    mapping.assignsNilForMissingRelationships = YES;

    return mapping;
}

@end
