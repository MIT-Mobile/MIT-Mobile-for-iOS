#import "PersonDetails.h"
#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PersonDetails
@dynamic uid;
@dynamic affiliation, dept, title;
@dynamic name, givenname, surname;
@dynamic office, phone, home, fax, email;
@dynamic street, city, state;
@dynamic url, website;
@dynamic lastUpdate;
@dynamic favorite, favoriteIndex;

- (NSString *)address
{
    if (self.street && self.city && self.state) {
        return [NSString stringWithFormat:@"%@\n%@, %@", self.street, self.city, self.state];
    }
    return nil;
}

@end
