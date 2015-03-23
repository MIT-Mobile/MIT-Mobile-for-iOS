#import "MITMobiusResource.h"
#import "MITMobiusCategory.h"
#import "MITMobiusResourceAttribute.h"
#import "MITMobiusResourceOwner.h"
#import "MITMobiusTemplate.h"
#import "MITMobiusType.h"
#import "MITMobiusResourceAttributeValue.h"

@implementation MITMobiusResource

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
@dynamic coordinate;

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


    RKRelationshipMapping *categoryMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_category" toKeyPath:@"category" withMapping:[MITMobiusCategory objectMapping]];
    [mapping addPropertyMapping:categoryMapping];

    RKRelationshipMapping *typeMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_type" toKeyPath:@"type" withMapping:[MITMobiusType objectMapping]];
    [mapping addPropertyMapping:typeMapping];

    RKRelationshipMapping *templateMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_template" toKeyPath:@"template" withMapping:[MITMobiusTemplate objectMapping]];
    [mapping addPropertyMapping:templateMapping];

    RKRelationshipMapping *ownersMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"owner" toKeyPath:@"owners" withMapping:[MITMobiusResourceOwner objectMapping]];
    [mapping addPropertyMapping:ownersMapping];

    RKRelationshipMapping *attributesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"attribute_values" toKeyPath:@"attributes" withMapping:[MITMobiusResourceAttribute objectMapping]];
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

- (NSOrderedSet *)attributes
{
    [self willAccessValueForKey:@"attributes"];
    
    NSOrderedSet *attributes = [self primitiveValueForKey:@"attributes"];
    
    for (MITMobiusResourceAttribute *rAttribute in attributes) {

        NSMutableArray *valuesToDelete = [[NSMutableArray alloc] init];
        
        for (MITMobiusResourceAttributeValue *value in rAttribute.values) {
            
            if ([value.value length] == 0) {
                [valuesToDelete addObject:value];
            }
        }
        NSMutableOrderedSet *values = [rAttribute.values mutableCopy];
        [values removeObjectsInArray:valuesToDelete];
        rAttribute.values = values;
    }
    [self didAccessValueForKey:@"attributes"];
    
    return attributes;
}

@end
