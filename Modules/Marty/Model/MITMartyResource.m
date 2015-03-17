#import "MITMartyResource.h"
#import "MITMartyCategory.h"
#import "MITMartyResourceAttribute.h"
#import "MITMartyResourceOwner.h"
#import "MITMartyTemplate.h"
#import "MITMartyType.h"

@implementation MITMartyResource

@dynamic dlc;
@dynamic latitude;
@dynamic longitude;
@dynamic reservable;
@dynamic room;
@dynamic status;
@dynamic attributes;
@dynamic category;
@dynamic owners;
@dynamic template;
@dynamic type;
@dynamic searches;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}
+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"name" : @"name",
                               @"room" : @"room",
                               @"latitude" : @"latitude",
                               @"longitude" : @"longitude",
                               @"dlc" : @"dlc",
                               @"status" : @"status",
                               @"reservable" : @"reservable",
                               @"created_by" : @"createdBy",
                               @"date_created" : @"created",
                               @"modified_by" : @"modifiedBy",
                               @"date_modified" : @"modified"};
    [mapping addAttributeMappingsFromDictionary:mappings];


    RKRelationshipMapping *categoryMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_category" toKeyPath:@"category" withMapping:[MITMartyCategory objectMapping]];
    [mapping addPropertyMapping:categoryMapping];

    RKRelationshipMapping *typeMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_type" toKeyPath:@"type" withMapping:[MITMartyType objectMapping]];
    [mapping addPropertyMapping:typeMapping];

    RKRelationshipMapping *templateMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_template" toKeyPath:@"template" withMapping:[MITMartyTemplate objectMapping]];
    [mapping addPropertyMapping:templateMapping];

    RKRelationshipMapping *ownersMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"owner" toKeyPath:@"owners" withMapping:[MITMartyResourceOwner objectMapping]];
    [mapping addPropertyMapping:ownersMapping];

    RKRelationshipMapping *attributesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"attribute_values" toKeyPath:@"attributes" withMapping:[MITMartyResourceAttribute objectMapping]];
    [mapping addPropertyMapping:attributesMapping];

    mapping.assignsNilForMissingRelationships = YES;

    return mapping;
}

#pragma mark MKAnnotation

- (NSString*)title
{
    return self.name;
}

- (NSString*)subtitle
{
    return self.room;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

@end
