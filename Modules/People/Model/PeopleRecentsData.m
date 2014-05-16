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

+ (void) erasePerson:(NSString *)uid
{
    NSMutableArray *updatedRecents = [[self sharedData].recents mutableCopy];
    
    [[self sharedData].recents enumerateObjectsUsingBlock:^(PersonDetails *person, NSUInteger idx, BOOL *stop) {
        if ([[person valueForKey:@"uid"] isEqualToString:uid]) {
			[updatedRecents removeObjectAtIndex:idx];
            [CoreDataManager deleteObject:person];
			(*stop) = YES;
		}
    }];
    
    [self sharedData].recents = updatedRecents;
    
    [CoreDataManager saveData];
}

+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails
{
	[personDetails setValue:[NSDate date] forKey:@"lastUpdate"];
	
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

@end
