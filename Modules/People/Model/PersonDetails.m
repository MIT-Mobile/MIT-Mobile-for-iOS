#import "PersonDetails.h"
#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PersonDetails

@synthesize uid, dept, email, fax, givenname, office, /*room, */surname, phone, title, lastUpdate;

// figure out if we already have this person in Favorites
// (CoreDataManager.h does not do selecting by criteria yet)
// this creates an insertedObject that needs to be committed or rolled back in results view
+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult
{
	NSString *uid = [selectedResult valueForKey:@"id"];
	if (uid.length > 8) {
		uid = [uid substringToIndex:8];
	}
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:PersonDetailsEntityName 
								   inManagedObjectContext:[CoreDataManager managedObjectContext]]];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uid = %@)", uid];
	[request setPredicate:pred];
	NSError *error;
	NSArray *results = [[CoreDataManager managedObjectContext] executeFetchRequest:request error:&error];
    [request release];
	if ([results count] == 0)
		return [PeopleRecentsData createFromSearchResult:selectedResult];
	else 
		return [results objectAtIndex:0];
}


@end
