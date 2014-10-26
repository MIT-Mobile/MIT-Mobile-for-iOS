#import "MITDiningRetailVenue.h"
#import "MITDiningLocation.h"
#import "MITDiningRetailDay.h"
#import "MITDiningVenues.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningRetailVenue

@dynamic cuisine;
@dynamic descriptionHTML;
@dynamic favorite;
@dynamic homepageURL;
@dynamic iconURL;
@dynamic identifier;
@dynamic menuHTML;
@dynamic menuURL;
@dynamic name;
@dynamic payment;
@dynamic shortName;
@dynamic hours;
@dynamic location;
@dynamic venues;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_name" : @"shortName",
                                                  @"icon_url" : @"iconURL",
                                                  @"description_html" : @"descriptionHTML",
                                                  @"homepage_url" : @"homepageURL",
                                                  @"menu_html" : @"menuHTML",
                                                  @"menu_url" : @"menuURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"payment", @"cuisine"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:[MITDiningLocation objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"hours" toKeyPath:@"hours" withMapping:[MITDiningRetailDay objectMapping]]];
    
    [mapping setIdentificationAttributes:@[@"identifier"]];
    
    return mapping;
}

#pragma mark - Convenience Methods

- (BOOL)isOpenNow
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    BOOL isOpenNow = NO;
    for (MITDiningRetailDay *retailDay in self.hours) {
        if (retailDay.startTimeString) {
            NSTimeInterval retailDayStartTime = [retailDay.startTime timeIntervalSince1970];
            NSTimeInterval retailDayEndTime = [retailDay.endTime timeIntervalSince1970];
            if (retailDayStartTime <= currentTime && currentTime <= retailDayEndTime) {
                isOpenNow = YES;
                break;
            }
        }
    }
    return isOpenNow;
}

- (MITDiningRetailDay *)retailDayForDate:(NSDate *)date
{
    MITDiningRetailDay *returnDay = nil;
    if (date) {
        NSDate *startOfDate = [date startOfDay];
        for (MITDiningRetailDay *retailDay in self.hours) {
            if ([retailDay.date isEqualToDateIgnoringTime:startOfDate]) {
                returnDay = retailDay;
                break;
            }
        }
    }
    return returnDay;
}

- (NSString *)hoursToday
{
    NSString *hoursSummary = nil;
    
    NSDate *nowDate = [NSDate date];
    NSTimeInterval nowInterval = [nowDate timeIntervalSince1970];
    
    MITDiningRetailDay *yesterdayRetailDay = [self retailDayForDate:nowDate];
    NSTimeInterval yesterdayEndTime = [yesterdayRetailDay.endTime timeIntervalSince1970];
    if (nowInterval < yesterdayEndTime) {
        hoursSummary = [yesterdayRetailDay hoursSummary];
    } else {
        MITDiningRetailDay *todayRetailDay = [self retailDayForDate:nowDate];
        hoursSummary = [todayRetailDay hoursSummary];
    }
    
    return hoursSummary;
}

@end
