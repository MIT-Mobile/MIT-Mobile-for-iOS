#import "RetailVenue.h"
#import "VenueLocation.h"
#import "CoreDataManager.h"

@implementation RetailVenue

@dynamic name;
@dynamic shortName;
@dynamic descriptionHTML;
@dynamic paymentMethods;
@dynamic cuisines;
@dynamic url;
@dynamic homepageURL;
@dynamic menuURL;
@dynamic iconURL;
@dynamic hours;
@dynamic building;
@dynamic sortableBuilding;
@dynamic location;

+ (RetailVenue *)newVenueWithDictionary:(NSDictionary *)dict {
    RetailVenue *venue = [CoreDataManager insertNewObjectForEntityForName:@"RetailVenue"];
    
    venue.name = dict[@"name"];
    venue.shortName = dict[@"short_name"];
    venue.url = dict[@"url"];
    venue.iconURL = dict[@"icon_url"];
    if (dict[@"homepage_url"]) {
        venue.homepageURL = dict[@"homepage_url"];
    }
    if (dict[@"menu_url"]) {
        venue.menuURL = dict[@"menu_url"];
    }
    if (dict[@"description_html"]) {
        venue.descriptionHTML = dict[@"description_html"];
    }
    
    venue.location = [VenueLocation newLocationWithDictionary:dict[@"location"]];
    
    // DiningMapListViewController groups RetailVenues by building.
    // Building is derived from roomNumber.
    // If no roomNumber, it goes into @"Other"
    
    if (venue.location.roomNumber) {
        NSString *roomNumber = venue.location.roomNumber;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(N|NW|NE|W|WW|E)?(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:roomNumber options:0 range:NSMakeRange(0, [roomNumber length])];
        if (result) {
            venue.building = [roomNumber substringWithRange:result.range];

            // Due to the way NSFetchRequest works, we can only sort by a simple string comparator.
            // In order to get building numbers to sort in natural order, we pad them with spaces and store that into sortableBuilding.
            // e.g. "7", "NE49", "W4", "W20" turn into
            //      "0    7"
            //      "NE   49"
            //      "W    4"
            //      "W   20"

            NSRange letterRange = [result rangeAtIndex:1];
            NSString *letters;
            if (letterRange.location != NSNotFound) {
                letters = [roomNumber substringWithRange:letterRange];
            } else {
                letters = @"0";
            }

            NSRange numberRange = [result rangeAtIndex:2];
            NSString *numbers;
            if (numberRange.location != NSNotFound) {
                numbers = [roomNumber substringWithRange:numberRange];
            } else {
                numbers = @"0";
            }
            
            venue.sortableBuilding = [NSString stringWithFormat:@"%s%5s", [letters UTF8String], [numbers UTF8String]];
        }
    }
    if (!venue.building) {
        venue.building = @"Other";
        venue.sortableBuilding = [NSString stringWithFormat:@"%5s%5s", [@"ZZZZZ" UTF8String], [@"99999" UTF8String]];
    }
    
    NSMutableArray *paymentMethods = [NSMutableArray array];
    for (NSString *payment in dict[@"payment"]) {
        [paymentMethods addObject:payment];
    }
    venue.paymentMethods = paymentMethods;
    
    NSMutableArray *cuisines = [NSMutableArray array];
    for (NSString *cuisine in dict[@"cuisine"]) {
        [cuisines addObject:cuisine];
    }
    venue.cuisines = cuisines;
    
    return venue;
}

- (NSArray *)paymentMethods {
    [self willAccessValueForKey:@"paymentMethods"];
    NSArray *methods = [[self primitiveValueForKey:@"paymentMethods"] sortedArrayUsingSelector:@selector(compare:)];
    [self didAccessValueForKey:@"paymentMethods"];
    return methods;
}

@end
