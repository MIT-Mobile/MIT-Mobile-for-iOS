#import "CalendarDataManager.h"
#import "MITConstants.h"
#import "CoreDataManager.h"

@implementation CalendarDataManager

+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(CalendarEventListType)listType category:(NSNumber *)catID
{
	// search from beginning of (day|month|fiscalYear) for (regular|academic|holiday) calendars
    NSDateComponents *components = nil;
    switch (listType) {
        case CalendarEventListTypeHoliday:
            components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit)
                                                         fromDate:startDate];
            int year = [components month] <= 6 ? [components year] - 1 : [components year];
            [components setYear:year];
            [components setMonth:7];
            break;
        case CalendarEventListTypeAcademic:
            components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit)
                                                         fromDate:startDate];
            break;
        default:
            components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                                         fromDate:startDate];
            break;
    }
    
	startDate = [[NSCalendar currentCalendar] dateFromComponents:components];
	
	NSTimeInterval interval = [CalendarConstants intervalForEventType:listType
															 fromDate:startDate
															  forward:YES];
	NSDate *endDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:startDate];

    NSPredicate *pred = nil;
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *events = nil;
    if (listType == CalendarEventListTypeEvents && catID == nil) {
        pred = [NSPredicate predicateWithFormat:@"(start >= %@) and (start < %@) and (isRegular == YES)", startDate, endDate];
        events = [CoreDataManager objectsForEntity:CalendarEventEntityName matchingPredicate:pred sortDescriptors:[NSArray arrayWithObject:sort]];
        
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
        EventCategory *category = nil;
        switch (listType) {
            case CalendarEventListTypeEvents:
                category = [CalendarDataManager categoryWithID:[catID intValue]];
                break;
            case CalendarEventListTypeExhibits:
                category = [CalendarDataManager categoryForExhibits];
                break;
            case CalendarEventListTypeAcademic:
                category = [CalendarDataManager categoryWithID:kCalendarAcademicCategoryID];
                break;
            case CalendarEventListTypeHoliday:
                category = [CalendarDataManager categoryWithID:kCalendarHolidayCategoryID];
                break;
            default:
                break;
        }
        
        // there are so few holidays that we won't filter out ones that have passed
        NSSet *eventSet;
        eventSet = [[category events] filteredSetUsingPredicate:pred];
        events = [[eventSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    [sort release];
	[endDate release];
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
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	NSSet *categories = [CoreDataManager objectsForEntity:CalendarCategoryEntityName
										matchingPredicate:pred
										  sortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	for (EventCategory *category in categories) {
		if (category.parentCategory == category) {
			[result addObject:category];
		}
	}

	if ([result count] > 0) {
		return result;
	}
	
	return nil;
}

+ (EventCategory *)categoryWithID:(NSInteger)catID
{	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"catID == %d", catID];
	EventCategory *category = [[CoreDataManager objectsForEntity:CalendarCategoryEntityName
											   matchingPredicate:pred] lastObject];
	if (!category) {
        category = (EventCategory *)[CoreDataManager insertNewObjectForEntityForName:CalendarCategoryEntityName];
		category.catID = [NSNumber numberWithInt:catID];
        if (catID == kCalendarAcademicCategoryID) {
            category.title = [CalendarConstants titleForEventType:CalendarEventListTypeAcademic];
        } else if (catID == kCalendarHolidayCategoryID) {
            category.title = [CalendarConstants titleForEventType:CalendarEventListTypeHoliday];
        }
        [CoreDataManager saveData];
	} else {
        //NSLog(@"%@", [[category.events allObjects] description]);
    }
	return category;
}

+ (EventCategory *)categoryWithDict:(NSDictionary *)dict
{
    NSInteger catID = [[dict objectForKey:@"catid"] intValue];
	EventCategory *category = [CalendarDataManager categoryWithID:catID];
	[category updateWithDict:dict];
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

	NSInteger eventID = [[dict objectForKey:@"id"] intValue];
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
    [freshDate release];
}

@end
