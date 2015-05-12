#import "MITMobiusResource.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusResourceDLC.h"
#import "MITMobiusResourceHours.h"
#import "MITMobiusResourceOwner.h"
#import "MITMobiusAttributeValue.h"
#import "MITMobiusImage.h"
#import "MITMobiusRoomSet.h"
#import "Foundation+MITAdditions.h"
#import "MITMobiusDailyHoursObject.h"

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

- (NSString *)getHoursStringForDate:(NSDate *)date;
{
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    
    for (MITMobiusResourceHours *resourceHours in self.hours) {
        if ([[date dateWithoutTime] dateFallsBetweenStartDate:[resourceHours.startDate dateWithoutTime] endDate:[resourceHours.endDate dateWithoutTime]]) {
            
            NSString *resourceHoursString = [NSString stringWithFormat:@"%@ - %@",[resourceHours.startDate MITShortTimeOfDayString], [resourceHours.endDate MITShortTimeOfDayString]];

            [hours addObject:resourceHoursString];
        }
    }
    return [hours componentsJoinedByString:@", "];
}

- (NSArray *)getArrayOfDailyHoursObjects
{
    NSArray *sortedResourceHours = [[self.hours allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *first = [(MITMobiusResourceHours *)obj1 startDate];
        NSDate *second = [(MITMobiusResourceHours *)obj2 startDate];
        return [first compare:second];
    }];
    
    NSMutableArray *dailyHoursObjectsArray = [[NSMutableArray alloc] init];
    
    [sortedResourceHours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *hours, NSUInteger idx, BOOL *stop) {

        MITMobiusDailyHoursObject *dailyHoursObject = [[MITMobiusDailyHoursObject alloc] init];

        NSDateFormatter *weekday = [[NSDateFormatter alloc] init];
        [weekday setDateFormat: @"EEEE"];
        dailyHoursObject.dayName = [weekday stringFromDate:hours.startDate];
        
        NSString *startTime = [hours.startDate MITShortTimeOfDayString];
        NSString *endTime = [hours.endDate MITShortTimeOfDayString];
        
        dailyHoursObject.hours = [NSString stringWithFormat:@"%@ - %@",startTime, endTime];
        [dailyHoursObjectsArray addObject:dailyHoursObject];
    }];
    return dailyHoursObjectsArray;
}

- (BOOL)isOpenOnDate:(NSDate *)date
{
    for (MITMobiusResourceHours *resourceHours in self.hours) {
        if ([date dateFallsBetweenStartDate:resourceHours.startDate endDate:resourceHours.endDate]) {
            return YES;
        }
    }
    return NO;
}

// Returns something like "Make - Model", "Make", or "Model".
// If multiple makes and models, "Make, Make - Model, Model".
- (NSString *)makeAndModel {
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:2];
    
    for (MITMobiusResourceAttributeValueSet *set in self.attributeValues) {
        if ([set.label caseInsensitiveCompare:@"make"] == NSOrderedSame) {
            NSArray *values = [[set.values allObjects] valueForKey:@"value"];
            NSString *joined = [values componentsJoinedByString:@", "];
            if ([joined length] > 0) {
                [components insertObject:joined atIndex:0];
            }
            continue;
        }
        if ([set.label caseInsensitiveCompare:@"model"] == NSOrderedSame) {
            NSArray *values = [[set.values allObjects] valueForKey:@"value"];
            NSString *joined = [values componentsJoinedByString:@", "];
            if ([joined length] > 0) {
                [components addObject:joined];
            }
            continue;
        }
        if ([components count] == 2) {
            break;
        }
    }
    
    return [components componentsJoinedByString:@" - "];
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
    if (self.latitude && self.longitude) {
        return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
    } else {
        return kCLLocationCoordinate2DInvalid;
    }
}

@end
