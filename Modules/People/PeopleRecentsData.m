#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PeopleRecentsData
+ (PeopleRecentsData *)sharedData
{
    static PeopleRecentsData *sharedData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedData = [[self alloc] init];
    });
    
	return sharedData;
}


#pragma mark - CoreData interface

+ (PersonDetails *)personWithUID:(NSString *)uid
{
	return [CoreDataManager getObjectForEntity:PersonDetailsEntityName attribute:@"uid" value:uid];
}

- (id)init
{
    self = [super init];
    if (self) {
        NSMutableArray *recentPersons = [[NSMutableArray alloc] init];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO];
        for (PersonDetails *person in [CoreDataManager fetchDataForAttribute:PersonDetailsEntityName 
                                                              sortDescriptor:sortDescriptor]) {
            // if the person's result was viewed over X days ago, remove it
            if ([[person valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -1500000) {
                [CoreDataManager deleteObject:person]; // this invokes saveData
            } else {
                [recentPersons addObject:person]; // store in memory
            }
        }

        [CoreDataManager saveData];
        _recents = recentPersons;
    }

	return self;
}

+ (void)eraseAll
{
    [CoreDataManager deleteObjects:[[self sharedData] recents]];
    [CoreDataManager saveData];

    [self sharedData].recents = [[NSArray alloc] init];
}

+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult
{
	// the "id" field we receive from mobi is either the unix uid (more
	// common) or something derived from another field (ldap "dn"), the
	// former has an 8 char limit but until proven otherwise let's assume
	// we can truncate the latter to 8 chars without sacrificing uniqueness
	NSString *uid = searchResult[@"id"];
	if ([uid length] > 8) {
		uid = [uid substringToIndex:8];
    }

	[personDetails setValue:uid forKey:@"uid"];
	[personDetails setValue:[NSDate date] forKey:@"lastUpdate"];
	
	NSArray *fetchTags = @[@"givenname", @"surname", @"title", @"dept", @"email", @"phone", @"fax", @"office"];

	for (NSString *key in fetchTags) {
		if (searchResult[key]) {
			// if someone has multiple emails/phones join them into a string
			// we need to figure out which fields return multiple values
			[personDetails setValue:[searchResult[key] componentsJoinedByString:@","]
                             forKey:key];
		}
	}
	
	// put latest person on top; remove if the person is already there
	NSMutableArray *updatedRecents = [[self sharedData].recents mutableCopy];

    [[self sharedData].recents enumerateObjectsUsingBlock:^(PersonDetails *person, NSUInteger idx, BOOL *stop) {
        if ([[person valueForKey:@"uid"] isEqualToString:[personDetails valueForKey:@"uid"]]) {
			[updatedRecents removeObjectAtIndex:idx];
			(*stop) = YES;
		}
    }];

	[updatedRecents insertObject:personDetails
                         atIndex:0];
	[CoreDataManager saveData];

    [self sharedData].recents = updatedRecents;

	return personDetails;
}


+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult 
{
	PersonDetails *personDetails = (PersonDetails *)[CoreDataManager insertNewObjectForEntityForName:PersonDetailsEntityName];
	
	[self updatePerson:personDetails withSearchResult:searchResult];
	
	return personDetails;
}

@end
