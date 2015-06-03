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
    
    __block NSDate *lastDate = [[NSDate date] dateWithoutTime];
    
    [sortedResourceHours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *hours, NSUInteger idx, BOOL *stop) {
        // Fill in missing days as Closed
        while ([lastDate isEqualToDateIgnoringTime:hours.startDate] == NO && [lastDate timeIntervalSinceDate:hours.startDate] < 0) {
            MITMobiusDailyHoursObject *dailyHoursObject = [[MITMobiusDailyHoursObject alloc] init];
            dailyHoursObject.dayName = [self dayNameForDate:lastDate];
            dailyHoursObject.hours = @"Closed";
            [dailyHoursObjectsArray addObject:dailyHoursObject];

            lastDate = [lastDate dateByAddingDay];
        }
        
        lastDate = [hours.startDate dateByAddingDay];
        
        MITMobiusDailyHoursObject *dailyHoursObject = [[MITMobiusDailyHoursObject alloc] init];
        dailyHoursObject.dayName = [self dayNameForDate:hours.startDate];
        NSString *startTime = [hours.startDate MITShortTimeOfDayString];
        NSString *endTime = [hours.endDate MITShortTimeOfDayString];
        
        dailyHoursObject.hours = [NSString stringWithFormat:@"%@ - %@",startTime, endTime];
        [dailyHoursObjectsArray addObject:dailyHoursObject];
    }];
    
    // Add (7 - count) more closings on the end to round out the week.
    // Note this means shops without hours show up as closed all week.
    while ([dailyHoursObjectsArray count] < 7) {
        MITMobiusDailyHoursObject *dailyHoursObject = [[MITMobiusDailyHoursObject alloc] init];
        dailyHoursObject.dayName = [self dayNameForDate:lastDate];
        dailyHoursObject.hours = @"Closed";
        [dailyHoursObjectsArray addObject:dailyHoursObject];

        lastDate = [lastDate dateByAddingDay];
    }
    
    return dailyHoursObjectsArray;
}

// Returns strings like "Today 5/14" for today, "Thursday 5/14" for other days.
- (NSString *)dayNameForDate:(NSDate *)date
{
    NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc] init];
    [weekdayFormatter setDateFormat: @"EEEE"];
    
    NSDateFormatter *shortDateFormatter = [[NSDateFormatter alloc] init];
    shortDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"M/d" options:0 locale:[NSLocale currentLocale]];
    
    NSString *weekdayString = nil;
    if ([date isToday]) {
        weekdayString = @"Today";
    } else {
        weekdayString = [weekdayFormatter stringFromDate:date];
    }
    NSString *dateString = [shortDateFormatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@ %@", weekdayString, dateString];
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

    if (components.count > 0) {
        return [components componentsJoinedByString:@" - "];
    } else {
        return nil;
    }
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
