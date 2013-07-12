#import "HouseVenue.h"
#import "VenueLocation.h"
#import "DiningDay.h"
#import "DiningMeal.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

@implementation HouseVenue

@dynamic name;
@dynamic shortName;
@dynamic iconImage;
@dynamic iconURL;
@dynamic url;
@dynamic paymentMethods;
@dynamic menuDays;
@dynamic location;

+ (HouseVenue *)newVenueWithDictionary:(NSDictionary *)dict {
    HouseVenue *venue = [CoreDataManager insertNewObjectForEntityForName:@"HouseVenue"];
    
    venue.name = dict[@"name"];
    venue.shortName = dict[@"short_name"];
    venue.iconURL = dict[@"icon_url"];
    venue.url = dict[@"url"];

    venue.location = [VenueLocation newLocationWithDictionary:dict[@"location"]];

    NSMutableSet *paymentMethods = [NSMutableSet set];
    for (NSString *payment in dict[@"payment"]) {
        [paymentMethods addObject:payment];
    }
    venue.paymentMethods = paymentMethods;
    
    for (NSDictionary *dayDict in dict[@"meals_by_day"]) {
        DiningDay *day = [DiningDay newDayWithDictionary:dayDict];
        if (day) {
            [venue addMenuDaysObject:day];
        }
    }
    
    return venue;
}

- (BOOL)isOpenNow {
    NSDate *date = [NSDate date];
    DiningDay *today = [self dayForDate:date];
    DiningMeal *meal = [today mealForDate:date];

    return (meal != nil);
}

- (NSString *)hoursNow {
    // TODO: current startTime/endTime time range
    return @"Open until 11am";
    // next time range
    // return @"Closed until 5pm";
    // no more time ranges for today
    // return @"Closed";
    // closed with a message
    // return @"Closed for renovations"
}

- (NSString *)hoursToday {
    return [self hoursForDate:[NSDate date]];
}

- (NSString *)hoursForDate:(NSDate *)date {
    DiningDay *day = [self dayForDate:date];
    return day.allHoursSummary;
}

- (DiningDay *)dayForDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSDate *dayDate = [calendar dateFromComponents:components];
    
    NSSet *matchingDays = [self.menuDays filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"date == %@", dayDate]];
    
    return [matchingDays anyObject];
}

- (DiningMeal *)bestMealForDate:(NSDate *)date {
    return [[self dayForDate:date] bestMealForDate:date];
}

- (NSString *)description {
    return [NSString stringWithFormat:
     @"name: %@ shortName: %@ payment: %@ url: %@ \n"
     , self.name, self.shortName, [[self.paymentMethods allObjects] componentsJoinedByString:@", "], self.url];
}


#pragma mark MGSAnnotation
- (MGSAnnotationType) annotationType
{
    return MGSAnnotationMarker;
}

- (CLLocationCoordinate2D) coordinate
{
    return CLLocationCoordinate2DMake([self.location.latitude doubleValue], [self.location.longitude doubleValue]);
}

- (NSString *) title
{
    return self.name;
}

- (NSString *) detail
{
    return self.location.displayDescription;
}


@end
