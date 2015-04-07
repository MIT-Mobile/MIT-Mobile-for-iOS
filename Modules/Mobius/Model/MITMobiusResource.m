#import "MITMobiusResource.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusResourceDLC.h"
#import "MITMobiusResourceHours.h"
#import "MITMobiusResourceOwner.h"
#import "MITMobiusAttributeValue.h"
#import "MITMobiusImage.h"
#import "MITMobiusRoomSet.h"

@implementation MITMobiusResource

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic reservable;
@dynamic room;
@dynamic status;
@dynamic attributeValues;
@dynamic category;
@dynamic dlc;
@dynamic hours;
@dynamic owners;
@dynamic roomset;
@dynamic type;
@dynamic images;

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

    RKRelationshipMapping *imagesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"_image"
                                                                                         toKeyPath:@"images"
                                                                                       withMapping:[MITMobiusImage objectMapping]];
    [mapping addPropertyMapping:imagesMapping];


    RKRelationshipMapping *roomsetMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"roomset"
                                                                                         toKeyPath:@"roomset"
                                                                                       withMapping:[MITMobiusRoomSet objectMapping]];
    [mapping addPropertyMapping:roomsetMapping];


    RKRelationshipMapping *attributeValuesMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"attribute_values"
                                                                                                toKeyPath:@"attributeValues"
                                                                                              withMapping:[MITMobiusResourceAttributeValueSet objectMapping]];

    [mapping addPropertyMapping:attributeValuesMapping];

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
