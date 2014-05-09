#import "CalendarDataManager.h"
#import "MITConstants.h"
#import "CoreDataManager.h"
#import "MITEventList.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

NSString * const CalendarStateEventList = @"events";
NSString * const CalendarStateCategoryList = @"categories";
NSString * const CalendarStateCategoryEventList = @"category";
//NSString * const CalendarStateSearchHome = @"search";
//NSString * const CalendarStateSearchResults = @"results";
NSString * const CalendarStateEventDetail = @"detail";

NSString * const CalendarEventAPIDay = @"day";
NSString * const CalendarEventAPISearch = @"search";

@interface CalendarDataManager ()
@property (copy) NSArray *eventLists;
@property (copy) NSArray *staticEventListIDs;

+ (NSArray *)staticEventTypes;

@end


@implementation CalendarDataManager
+ (CalendarDataManager *)sharedManager {
    static CalendarDataManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[CalendarDataManager alloc] init];
    });
    
    return sharedManager;
}

- (id)init
{
	self = [super init];
    
	if (self) {
		[self requestEventLists];
	}
    
	return self;
}

- (void)requestEventLists {
	// first assemble anything we already have
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
	self.eventLists = [CoreDataManager objectsForEntity:@"MITEventList" matchingPredicate:nil sortDescriptors:@[sort]];

	NSArray *staticLists = [CalendarDataManager staticEventTypes];
	
	NSMutableArray *staticEvents = [[NSMutableArray alloc] init];
	for (MITEventList *aList in staticLists) {
		[staticEvents addObject:aList.listID];
	}
    
	self.staticEventListIDs = staticEvents;

    NSURLRequest *request = [NSURLRequest requestForModule:CalendarTag command:@"extraTopLevels" parameters:@{@"version" : @(2)}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSArray *eventLists) {
        if ([eventLists isKindOfClass:[NSArray class]]) {
            NSMutableArray *newLists = [NSMutableArray arrayWithArray:[CalendarDataManager staticEventTypes]];

            [eventLists enumerateObjectsUsingBlock:^(NSDictionary *eventList, NSUInteger idx, BOOL *stop) {
                MITEventList *eventListObject = [CalendarDataManager eventListWithID:eventList[@"type"]];
                eventListObject.title = eventList[@"shortName"];
                eventListObject.sortOrder = @(idx + 1);
                [newLists addObject:eventListObject];
            }];

            NSSet *newEventLists = [NSSet setWithArray:newLists];
            NSSet *currentEventLists = [NSSet setWithArray:self.eventLists];
            if (![currentEventLists isEqualToSet:newEventLists]) {
                DDLogVerbose(@"event lists have changed");
                [CoreDataManager saveData];

                // check for deleted categories
                NSMutableSet *newEventListIDs = [[NSMutableSet alloc] init];

                for (MITEventList *newEventList in newLists) {
                    [newEventListIDs addObject:newEventList.listID];
                }

                for (MITEventList *oldEventList in self.eventLists) {
                    if (![newEventListIDs containsObject:oldEventList.listID]) {
                        DDLogVerbose(@"deleting old list %@", [oldEventList description]);
                        [CoreDataManager deleteObject:oldEventList];
                    }
                }

                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
                self.eventLists = [newLists sortedArrayUsingDescriptors:@[sort]];
                if ([self.delegate respondsToSelector:@selector(calendarListsLoaded)]) {
                    [self.delegate calendarListsLoaded];
                }
            }
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        if ([[CoreDataManager managedObjectContext] hasChanges]) {
            [[CoreDataManager managedObjectContext] rollback];
        }

        if ([self.delegate respondsToSelector:@selector(calendarListsFailedToLoad)]) {
            [self.delegate calendarListsFailedToLoad];
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (BOOL)isDailyEvent:(MITEventList *)listType {
	if ([listType.listID isEqualToString:@"Events"]) {
		return YES;
	}
    
    if ([listType.listID isEqualToString:@"OpenHouse"]) {
        return NO;
    }
    
	return ![self.staticEventListIDs containsObject:listType.listID];
}

- (MITEventList *)eventListWithID:(NSString *)listID {
	for (MITEventList *aList in self.eventLists) {
		if ([aList.listID isEqualToString:listID])
			return aList;
	}
	return nil;
}

+ (NSArray *)staticEventTypes {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"staticEventTypes" ofType:@"plist" inDirectory:@"calendar"];
	NSArray *staticEventData = [NSArray arrayWithContentsOfFile:path];
    
	NSMutableArray *mutableArray = [NSMutableArray array];
	for (NSDictionary *listInfo in staticEventData) {
		MITEventList *eventList = [CalendarDataManager eventListWithID:listInfo[@"listID"]];
		if (!eventList.title || !eventList.sortOrder) {
			eventList.title = listInfo[@"title"];
			eventList.sortOrder = @([listInfo[@"sortOrder"] integerValue]);
			[CoreDataManager saveData];
		}
        
		[mutableArray addObject:eventList];
	}
    
	return mutableArray;
}

#pragma mark -

+ (MITEventList *)eventListWithID:(NSString *)listID {
	MITEventList *result = nil;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"listID like %@", listID];
	NSArray *lists = [CoreDataManager objectsForEntity:@"MITEventList" matchingPredicate:pred];
	if ([lists count]) {
		result = [lists lastObject];
	} else {
		result = [CoreDataManager insertNewObjectForEntityForName:@"MITEventList"];
		result.listID = listID;
	}
	return result;
}

+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(MITEventList *)listType category:(NSNumber *)catID
{
	// search from beginning of (day|month|fiscalYear) for (regular|academic|holiday) calendars
    NSDateComponents *components = nil;
	if ([listType.listID isEqualToString:@"holidays"]) {
		components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit)
													 fromDate:startDate];
		int year = [components month] <= 6 ? [components year] - 1 : [components year];
		[components setYear:year];
		[components setMonth:7];
	} else if ([listType.listID isEqualToString:@"academic"]) {
		components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit)
													 fromDate:startDate];
	} else {
		components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
													 fromDate:startDate];
    }
    
	startDate = [[NSCalendar currentCalendar] dateFromComponents:components];
	
	NSTimeInterval interval = [CalendarDataManager intervalForEventType:listType
															   fromDate:startDate
																forward:YES];
	NSDate *endDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:startDate];

    NSPredicate *pred = nil;
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *events = nil;
    //if (listType == CalendarEventListTypeEvents && catID == nil) {
	if ([listType.listID isEqualToString:@"Events"]) {
        pred = [NSPredicate predicateWithFormat:@"(start >= %@) and (start < %@) and (ANY lists.title like '%@')", startDate, endDate, @"Events"];
        events = [CoreDataManager objectsForEntity:CalendarEventEntityName matchingPredicate:pred sortDescriptors:@[sort]];
        
        // simple check for whether the cached events are from a previous load of
        // all of today's events or from a category; if the latter then we need a network request
        NSPredicate *nilPred = [NSPredicate predicateWithFormat:@"(categories.@count == 0)"];
        // "new" because user has not seen its details or which category its in
        NSArray *newEvents = [events filteredArrayUsingPredicate:nilPred];
        if (![newEvents count]) {
            events = nil;
        }
        
    } else {
        pred = [NSPredicate predicateWithFormat:@"(start >= %@) and (start < %@)", startDate, endDate];
		
		NSSet *eventSet = [listType.events filteredSetUsingPredicate:pred];
        events = [[eventSet allObjects] sortedArrayUsingDescriptors:@[sort]];
    }
    
    return events;
}

+ (EventCategory *)categoryWithName:(NSString *)categoryName
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"title like %@", categoryName];
	EventCategory *category = [[CoreDataManager objectsForEntity:CalendarCategoryEntityName
											   matchingPredicate:pred] lastObject];
    return category;
}

+ (EventCategory *)categoryForExhibits
{
    return [CalendarDataManager categoryWithName:@"Exhibits"];
}

+ (NSArray *)topLevelCategories
{
	NSPredicate *topLevelPredicate = [NSPredicate predicateWithFormat:@"listID == nil AND ((parentCategory == nil) OR (parentCategory == self))"];
	NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	NSArray *categories = [CoreDataManager objectsForEntity:CalendarCategoryEntityName
                                          matchingPredicate:topLevelPredicate
                                            sortDescriptors:@[titleSortDescriptor]];
    
    // (bskinner - 2013.08)
    // Need to fix an issue in the categories management.
    // Prior to this, each EventCategory would keep a strong reference
    //  to itself in the 'parentCategory' relation to mark it as a top-
    //  level category. This creates a retain cycle for the top level
    //  objects so, instead, the top-level categories have been redefined
    //  to have a 'nil' parent.
    __block BOOL saveNeeded = NO;
    [categories enumerateObjectsUsingBlock:^(EventCategory *category, NSUInteger idx, BOOL *stop) {
        if ([category.parentCategory isEqual:category]) {
            category.parentCategory = nil;
            saveNeeded = YES;
        }
    }];
    
    if (saveNeeded) {
        [[CoreDataManager coreDataManager] saveData];
    }
    
    return categories;
}

+ (NSArray *)openHouseCategories
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"listID == %@", @"OpenHouse"];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	return [CoreDataManager objectsForEntity:CalendarCategoryEntityName
                           matchingPredicate:pred
                             sortDescriptors:@[sort]];
}

+ (EventCategory *)categoryWithID:(NSInteger)catID forListID:(NSString *)listID;
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"catID == %d AND listID == %@", catID, listID];
	EventCategory *category = [[CoreDataManager objectsForEntity:CalendarCategoryEntityName
											   matchingPredicate:pred] lastObject];
	if (!category) {
        category = (EventCategory *)[CoreDataManager insertNewObjectForEntityForName:CalendarCategoryEntityName];
		category.catID = @(catID);
        category.listID = listID;
        [CoreDataManager saveData];
	}
    
	return category;
}

+ (EventCategory *)categoryWithDict:(NSDictionary *)dict forListID:(NSString *)listID;
{
    NSInteger catID = [dict[@"catid"] intValue];
	EventCategory *category = [CalendarDataManager categoryWithID:catID forListID:listID];
	[category updateWithDict:dict forListID:listID];
	return category;
}

+ (MITCalendarEvent *)eventWithID:(NSInteger)eventID
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"eventID == %d", eventID];
	MITCalendarEvent *event = [[CoreDataManager objectsForEntity:CalendarEventEntityName
											matchingPredicate:pred] lastObject];
	if (!event) {
		event = [CoreDataManager insertNewObjectForEntityForName:CalendarEventEntityName];
		event.eventID = [NSNumber numberWithInt:eventID];
	}
	return event;
}

+ (MITCalendarEvent *)eventWithDict:(NSDictionary *)dict
{
	// purge rogue categories that the soap server doesn't return
	// from the "categories" api call but show up in events
	if ([[CoreDataManager managedObjectContext] hasChanges]) {
		[[CoreDataManager managedObjectContext] undo];
		[[CoreDataManager managedObjectContext] rollback];
	}

	NSInteger eventID = [dict[@"id"] integerValue];
	MITCalendarEvent *event = [CalendarDataManager eventWithID:eventID];	
	[event updateWithDict:dict];
	return event;
}

+ (void)pruneOldEvents
{
    NSDate *freshDate = [[NSDate alloc] initWithTimeInterval:-kCalendarEventTimeoutSeconds
                                                   sinceDate:[NSDate date]];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(lastUpdated < %@)", freshDate];
    NSArray *events = [CoreDataManager objectsForEntity:CalendarEventEntityName matchingPredicate:pred];
    if ([events count]) {
        [CoreDataManager deleteObjects:events];
        [CoreDataManager saveData];
    }
}

#pragma mark formerly defined in CalendarConstants

+ (NSString *)apiCommandForEventType:(MITEventList *)listType
{
	if (![[CalendarDataManager sharedManager] isDailyEvent:listType]) {
		return listType.listID;
	} else {
		return CalendarEventAPIDay;
	}
}

+ (NSString *)dateStringForEventType:(MITEventList *)listType forDate:(NSDate *)aDate
{
	NSDate *now = [NSDate date];
	if ([[CalendarDataManager sharedManager] isDailyEvent:listType]
		&& [now compare:aDate] != NSOrderedAscending
		&& [now timeIntervalSinceDate:aDate] < [CalendarDataManager intervalForEventType:listType fromDate:aDate forward:YES]) {
		return @"Today";
	}
	
	NSString *dateString = nil;
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	if ([listType.listID isEqualToString:@"academic"]) {
		[df setDateFormat:@"MMMM yyyy"];
		dateString = [df stringFromDate:aDate];
	} else if ([listType.listID isEqualToString:@"holidays"]) {
		// Find which Academic Year / Fiscal Year `aDate` falls under.
        // MIT's calendar starts July 1st and ends June 30th. 
        // e.g. 5/10/2012 would be in FY12 and comes out as the @"2011-2012" year.
        
		[df setDateFormat:@"yyyy"];
        // Ignore the user's locale. MIT's calendar is based on the Gregorian calendar.
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *comps = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:aDate];
		if ([comps month] <= 6) {
			[comps setYear:[comps year] - 1];
        }
        NSDate *startDate = [calendar dateFromComponents:comps];
        [comps setYear:[comps year] + 1];
        NSDate *endDate = [calendar dateFromComponents:comps];
        dateString = [NSString stringWithFormat:@"%@-%@", [df stringFromDate:startDate], [df stringFromDate:endDate]];
	} else {
		[df setDateStyle:kCFDateFormatterMediumStyle];
		dateString = [df stringFromDate:aDate];
    }
    
	
	return dateString;
}

+ (NSTimeInterval)intervalForEventType:(MITEventList *)listType fromDate:(NSDate *)aDate forward:(BOOL)forward
{
	NSInteger sign = forward ? 1 : -1;
	if ([listType.listID isEqualToString:@"academic"]) {
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *comps = [[NSDateComponents alloc] init];
		[comps setMonth:sign];
		NSDate *targetDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
		return [targetDate timeIntervalSinceDate:aDate];
	}
	else if ([listType.listID isEqualToString:@"holidays"]) {
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *comps = [[NSDateComponents alloc] init];
		[comps setYear:sign];
		NSDate *targetDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
		return [targetDate timeIntervalSinceDate:aDate];
	} else {
		return 86400.0 * sign;
	}
}

- (EventCategory *)openHouseCategoryWithTitle:(NSString *)title catId:(NSInteger)catId {
    NSDictionary *dict = @{@"name" : title,
                           @"catid" : @(catId)};
    
    return [CalendarDataManager categoryWithDict:dict
                                       forListID:@"OpenHouse"];
}

- (void)makeOpenHouseCategoriesRequest {
    // hard code the open house categories (to avoid the complexity that occurs
    // when people scan QR codes for open house categories that have yet to be loaded
    // from the server
    [self openHouseCategoryWithTitle:@"Engineering, Technology, and Invention"  catId:39];
    [self openHouseCategoryWithTitle:@"Energy, Environment, and Sustainability" catId:40];
    [self openHouseCategoryWithTitle:@"Entrepreneurship and Management"         catId:41];
    [self openHouseCategoryWithTitle:@"Life Sciences and Biotechnology"         catId:42];
    [self openHouseCategoryWithTitle:@"The Sciences"                            catId:43];
    [self openHouseCategoryWithTitle:@"Air and Space Flight"                    catId:44];
    [self openHouseCategoryWithTitle:@"Architecture, Planning, and Design"      catId:45];
    [self openHouseCategoryWithTitle:@"Arts, Humanities, and Social Sciences"   catId:46];
    [self openHouseCategoryWithTitle:@"MIT Learning, Life, and Culture"         catId:47];
}

- (NSString *)getOpenHouseCatIdWithIdentifier:(NSString *)identifier {
    static NSDictionary *cachedIdentifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedIdentifiers = @{@"eng" : @"39",
                              @"energy" : @"40",
                              @"entrepreneurship" : @"41",
                              @"biotech" : @"42",
                              @"sciences" : @"43",
                              @"air" : @"44",
                              @"architecture" : @"45",
                              @"humanities" : @"46",
                              @"life" : @"47"};
    });
    
    return cachedIdentifiers[identifier];
}

@end
