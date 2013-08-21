#import "PersonDetails.h"
#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PersonDetails
@dynamic uid;
@dynamic dept;
@dynamic email;
@dynamic fax;
@dynamic givenname;
@dynamic office;
@dynamic surname;
@dynamic phone;
@dynamic title;
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
