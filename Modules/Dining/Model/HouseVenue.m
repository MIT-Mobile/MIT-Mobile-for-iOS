#import "HouseVenue.h"
#import "VenueLocation.h"
#import "DiningDay.h"
#import "CoreDataManager.h"

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
    // [NSDate date] compared to days and startTime/endTime time ranges
    return true;
}

- (NSString *)hoursNow {
    // current startTime/endTime time range
    return @"Open until 11am";
    // next time range
    // return @"Closed until 5pm";
    // no more time ranges for today
    // return @"Closed";
    // closed with a message
    // return @"Closed for renovations"
}

- (NSString *)hoursToday {
    return @"8am - 11am, 11am - 1pm, 5pm - 9pm";
    // or closed with a message
    // return @"Closed for renovations"
}

- (NSString *)description {
    return [NSString stringWithFormat:
     @"name: %@ shortName: %@ payment: %@ url: %@ \n"
     , self.name, self.shortName, [[self.paymentMethods allObjects] componentsJoinedByString:@", "], self.url];
}

@end
