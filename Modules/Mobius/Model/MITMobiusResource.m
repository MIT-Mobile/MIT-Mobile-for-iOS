#import "MITMobiusResource.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusResourceDLC.h"
#import "MITMobiusResourceHours.h"
#import "MITMobiusResourceOwner.h"
#import "MITMobiusAttributeValue.h"

@implementation MITMobiusResource

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic reservable;
@dynamic room;
@dynamic status;
@dynamic attributes;
@dynamic attributeValues;
@dynamic category;
@dynamic dlc;
@dynamic hours;
@dynamic owners;
@dynamic roomset;
@dynamic type;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    NSDictionary *mappings = @{@"_id" : @"identifier",
                               @"name" : @"name",
                               @"room" : @"room",
                               @"latitude" : @"latitude",
                               @"longitude" : @"longitude",
                               @"status" : @"status",
                               @"reservable" : @"reservable",
                               @"_category.category" : @"category",
                               @"_type.type" : @"type"};

    [mapping addAttributeMappingsFromDictionary:mappings];


    RKEntityMapping *resourceOwnerMapping = [[RKEntityMapping alloc] initWithEntity:[MITMobiusResourceOwner entityDescription]];
    RKAttributeMapping *resourceOwnerNameMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil
                                                                                         toKeyPath:@"name"];
    [resourceOwnerMapping addPropertyMapping:resourceOwnerNameMapping];

    RKRelationshipMapping *ownersMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"owner"
                                                                                       toKeyPath:@"owners"
                                                                                     withMapping:resourceOwnerMapping];
    [mapping addPropertyMapping:ownersMapping];


    RKRelationshipMapping *hoursMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"hours"
                                                                                      toKeyPath:@"hours"
                                                                                    withMapping:[MITMobiusResourceHours objectMapping]];
    [mapping addPropertyMapping:hoursMapping];


    RKRelationshipMapping *attributeValuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"attribute_values" toKeyPath:@"attributeValues" withMapping:[MITMobiusResourceAttributeValueSet objectMapping]];
    [mapping addPropertyMapping:attributeValuesMapping];

    [mapping addConnectionForRelationship:@"attributes" connectedBy:@{@"attribute_values._attribute._id" : @"identifier"}];

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
    [self didAccessValueForKey:@"attributes"];

    for (MITMobiusAttribute *rAttribute in attributes) {

        NSMutableArray *valuesToDelete = [[NSMutableArray alloc] init];

        for (MITMobiusAttributeValue *value in rAttribute.values) {

            if ([value.value length] == 0) {
                [valuesToDelete addObject:value];
            }
        }
        NSMutableOrderedSet *values = [rAttribute.values mutableCopy];
        [values removeObjectsInArray:valuesToDelete];
        rAttribute.values = values;
    }
    
    return attributes;
}

@end
