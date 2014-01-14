#import "PersonDetails.h"
#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PersonDetails
@dynamic uid;
@dynamic affiliation, dept, title;
@dynamic name, givenname, surname;
@dynamic office, phone, homephone, fax, email;
@dynamic street, city, state;
@dynamic url, website;
@dynamic lastUpdate;

+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult
{
	NSString *uid = selectedResult[@"id"];
	if ([uid length] > 8) {
		uid = [uid substringToIndex:8];
	}
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"uid = %@", uid];
	NSArray *results = [CoreDataManager objectsForEntity:PersonDetailsEntityName matchingPredicate:pred];

	if ([results count]) {
		return [results lastObject];
	} else {
		return [PeopleRecentsData createFromSearchResult:selectedResult];
    }
}

- (NSString*)displayName {
    if ([self.surname length]) {
        if ([self.givenname length]) {
            return [NSString stringWithFormat:@"%@ %@",self.givenname, self.surname];
        }
    }

    return self.givenname;
}

@end
