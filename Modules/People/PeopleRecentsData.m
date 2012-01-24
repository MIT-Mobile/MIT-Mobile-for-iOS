#import "PeopleRecentsData.h"
#import "CoreDataManager.h"

@implementation PeopleRecentsData

@synthesize recents;

static PeopleRecentsData *sharedData = nil;

#pragma mark Singleton Boilerplate

+ (PeopleRecentsData *)sharedData
{
	if (sharedData == nil) {
		sharedData = [[super allocWithZone:NULL] init];
	}
	return sharedData;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedData] retain];	
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;	
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released	
}

- (oneway void)release
{
    //do nothing	
}

- (id)autorelease
{
    return self;	
}

#pragma mark -
#pragma mark Core data interface

+ (PersonDetails *)personWithUID:(NSString *)uid
{
	PersonDetails *person = [CoreDataManager getObjectForEntity:PersonDetailsEntityName attribute:@"uid" value:uid];
	return person;
}

- (id)init
{
    self = [super init];
    if (self) {
        recents = [[NSMutableArray alloc] initWithCapacity:0];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdate" ascending:NO];
        for (PersonDetails *person in [CoreDataManager fetchDataForAttribute:PersonDetailsEntityName 
                                                              sortDescriptor:sortDescriptor]) {
            // if the person's result was viewed over X days ago, remove it
            if ([[person valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -1500000) {
                [CoreDataManager deleteObject:person]; // this invokes saveData
            } else {
                [recents addObject:person]; // store in memory
            }
        }
        [CoreDataManager saveData];
        [sortDescriptor release];
    }
	return self;
}

+ (void)eraseAll
{
    [CoreDataManager deleteObjects:[[self sharedData] recents]];
    [CoreDataManager saveData];
	[[[self sharedData] recents] removeAllObjects];
}

+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult
{
	// the "id" field we receive from mobi is either the unix uid (more
	// common) or something derived from another field (ldap "dn"), the
	// former has an 8 char limit but until proven otherwise let's assume
	// we can truncate the latter to 8 chars without sacrificing uniqueness
	NSString *uid = [searchResult objectForKey:@"id"];
	if (uid.length > 8)
		uid = [uid substringToIndex:8];
	
	[personDetails setValue:uid forKey:@"uid"];
	[personDetails setValue:[NSDate date] forKey:@"lastUpdate"];
	
	NSArray *fetchTags = [NSArray arrayWithObjects:
						  @"givenname", @"surname", @"title", @"dept", @"email", @"phone", // @"homephone", 
						  @"fax", @"office", //@"room", @"address", @"city", @"state", 
						  nil];
	
	for (NSString *key in fetchTags) {
		NSArray *values = [searchResult objectForKey:key];
		if (values != nil) {
			// if someone has multiple emails/phones join them into a string
			// we need to figure out which fields return multiple values
			[personDetails setValue:[values componentsJoinedByString:@","] forKey:key];
		}
	}
	
	// put latest person on top; remove if the person is already there
	NSMutableArray *recentsData = [[self sharedData] recents];
	for (NSInteger i = 0; i < [recentsData count]; i++) {
		PersonDetails *oldPerson = [recentsData objectAtIndex:i];
		if ([[oldPerson valueForKey:@"uid"] isEqualToString:[personDetails valueForKey:@"uid"]]) {
			[recentsData removeObjectAtIndex:i];
			break;
		}
	}
	[recentsData insertObject:personDetails atIndex:0];
	
	[CoreDataManager saveData];
	
	return personDetails;
}


+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult 
{
	
	PersonDetails *personDetails = (PersonDetails *)[CoreDataManager insertNewObjectForEntityForName:PersonDetailsEntityName];
	
	[self updatePerson:personDetails withSearchResult:searchResult];
	
	return personDetails;
}

@end
