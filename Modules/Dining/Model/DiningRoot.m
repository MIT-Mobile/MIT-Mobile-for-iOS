#import "DiningRoot.h"
#import "HouseVenue.h"
#import "RetailVenue.h"
#import "CoreDataManager.h"
#import "DiningLink.h"

@implementation DiningRoot

@dynamic announcementsHTML;
@dynamic lastUpdated;
@dynamic links;
@dynamic houseVenues;
@dynamic retailVenues;

+ (DiningRoot *)newRootWithDictionary:(NSDictionary *)dict {

    DiningRoot *root = [CoreDataManager insertNewObjectForEntityForName:@"DiningRoot"];
    
    if (dict[@"announcements_html"]) {
        root.announcementsHTML = dict[@"announcements_html"];
    }
    
    NSArray *linksArray = dict[@"links"];
    if (linksArray && [linksArray isKindOfClass:[NSArray class]]) {
        
        [linksArray enumerateObjectsUsingBlock:^(NSDictionary *linkDict, NSUInteger idx, BOOL *stop) {
            DiningLink *link = [DiningLink newLinkWithDictionary:linkDict];
            link.ordinality = @(idx);
            [root addLinksObject:link];
        }];
    }
    
    NSArray *houseArray = dict[@"venues"][@"house"];
    if (houseArray && [houseArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *houseDict in houseArray) {
            [root addHouseVenuesObject:[HouseVenue newVenueWithDictionary:houseDict]];
        }
    }
    
    NSArray *retailArray = dict[@"venues"][@"retail"];
    if (retailArray && [retailArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *retailDict in retailArray) {
            [root addRetailVenuesObject:[RetailVenue newVenueWithDictionary:retailDict]];
        }
    }
    
    return root;
}

@end
