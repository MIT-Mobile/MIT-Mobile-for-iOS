#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarConstants.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "MITModuleURL.h"
#import "MITMobileWebAPI.h"
#import "CalendarEventMapAnnotation.h"
#import <MapKit/MapKit.h>

@interface CalendarModule (Private)

- (BOOL)localPathHelper:(NSString *)path queryDict:(NSDictionary *)queryDict;
- (void)setupMapView:(UIViewController *)theVC queryDict:(NSDictionary *)queryDict;

@end


@implementation CalendarModule

@synthesize calendarVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CalendarTag;
        self.shortName = @"Events";
        self.longName = @"Events Calendar";
        self.iconName = @"calendar";
        
        calendarVC = [[CalendarEventsViewController alloc] init];
		calendarVC.activeEventList = CalendarEventListTypeEvents;
		calendarVC.showList = YES;
		calendarVC.showScroller = YES;
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:calendarVC]];
    }
    return self;
}


- (void)applicationWillTerminate
{	
	MITModuleURL *url = [[MITModuleURL alloc] initWithTag:CalendarTag];
	
	UIViewController *visibleVC = [calendarVC.navigationController visibleViewController];
	CalendarEventsViewController *eventsVC;
	NSString *path = nil;
	NSString *parentPath = nil;
	NSMutableDictionary *queryDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// take care of CalendarDetailViewController, if any
	if ([visibleVC isMemberOfClass:[CalendarDetailViewController class]]) {
		path = CalendarStateEventDetail;
		NSInteger eventID = [((CalendarDetailViewController *)visibleVC).event.eventID intValue];

		// if there is an event detail screen, it will overwrite this with the same eventID
		[queryDict setObject:[NSString stringWithFormat:@"%d", eventID] forKey:@"eventID"];
		[calendarVC.navigationController popViewControllerAnimated:NO];
		eventsVC = (CalendarEventsViewController *)[calendarVC.navigationController visibleViewController];

	} else {
		eventsVC = (CalendarEventsViewController *)visibleVC;
	}

	// take care of last CalendarEventsViewController
	if ([eventsVC.tableView isMemberOfClass:[EventCategoriesTableView class]]) {
		parentPath = CalendarStateCategoryList;
		
	} else {
		if (!eventsVC.showList) {
			[queryDict setObject:@"yes" forKey:@"map"];
			
			CalendarEventMapAnnotation *annotation = (CalendarEventMapAnnotation *)eventsVC.mapView.currentAnnotation;
			if (annotation != nil) {
				NSInteger eventID = annotation.eventID;
				[queryDict setObject:[NSString stringWithFormat:@"%d", eventID] forKey:@"eventID"];
			}
			
			[queryDict setObject:[eventsVC.mapView serializeCurrentRegion] forKey:@"region"];
		}
		
		if (eventsVC.catID != kCalendarTopLevelCategoryID) {
			parentPath = CalendarStateCategoryEventList;
			[queryDict setObject:[NSString stringWithFormat:@"%d", eventsVC.catID]
						  forKey:@"catID"];
			
		} else {
			parentPath = CalendarStateEventList;
			[queryDict setObject:[NSString stringWithFormat:@"%d", eventsVC.activeEventList]
						  forKey:@"activeEventList"];
		}
	}

	if (path == nil) {
		path = parentPath;
	} else {
		[queryDict setObject:parentPath forKey:@"parentPath"];
	}
	
	NSTimeInterval interval = [eventsVC.startDate timeIntervalSinceNow];
	if (interval <= -86400.0 || interval >= 86400.0) {
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		[df setDateStyle:NSDateFormatterShortStyle];
		[queryDict setObject:[df stringFromDate:eventsVC.startDate] forKey:@"startDate"];
		[df release];
	}

	[url setPath:path query:[MITMobileWebAPI buildQuery:queryDict]];
	[url setAsModulePath];
	[url release];
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
	BOOL didHandle = NO;
	
	while (calendarVC.navigationController.visibleViewController != calendarVC) {
		[calendarVC.navigationController popViewControllerAnimated:NO];
	}
	
	// optional query parameters: activeEventList, showList, startDate (, endDate?)
	// parameters for subcategory screen only: catID
	// parameters for detail screen only: eventID, parentPath

	NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *queryDict = [NSMutableDictionary dictionaryWithCapacity:[queryComponents count]];
	for (NSString *component in queryComponents) {
		NSArray *args = [component componentsSeparatedByString:@"="];
		if ([args count] == 2) {
			[queryDict setObject:[args objectAtIndex:1] forKey:[args objectAtIndex:0]];
		}
	}

	if ([localPath isEqualToString:CalendarStateEventDetail]) {

		// restore all parent controllers
		NSString *parentPath = [queryDict objectForKey:@"parentPath"];				
		if ([self localPathHelper:parentPath queryDict:queryDict]) {

			// restore detail screen
			NSInteger eventID = [[queryDict objectForKey:@"eventID"] intValue];		
			CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] init];
            
			detailVC.event = [[CalendarDataManager eventWithID:eventID] retain];
			[calendarVC.navigationController pushViewController:detailVC animated:NO];
			[detailVC release];
			
			didHandle = YES;
		}
		
	} else {
        [CalendarDataManager pruneOldEvents];
		didHandle = [self localPathHelper:localPath queryDict:queryDict];
	}
	
	return didHandle;
}

- (BOOL)localPathHelper:(NSString *)path queryDict:(NSDictionary *)queryDict
{
	BOOL didHandle = NO;

	BOOL showList = ([queryDict objectForKey:@"map"] == nil);

	NSString *dateString = [queryDict objectForKey:@"startDate"];
	if (dateString != nil) {
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		[df setDateStyle:NSDateFormatterShortStyle];
		calendarVC.startDate = [df dateFromString:dateString];
		[df release];
	}

	// restore controllers
	
	if (path == nil || [path isEqualToString:CalendarStateEventList]) {
		// stack depth: 1
		NSString *listString = [queryDict objectForKey:@"activeEventList"];
		CalendarEventListType listType = (listString == nil) ? CalendarEventListTypeEvents : [listString intValue];
		calendarVC.activeEventList = listType;
		calendarVC.showList = showList;

        NSNumber *catID = (listType == CalendarEventListTypeExhibits) ? [CalendarDataManager categoryForExhibits].catID : nil;
		calendarVC.events = [CalendarDataManager eventsWithStartDate:calendarVC.startDate listType:listType category:catID];
		
		if (listType != CalendarEventListTypeEvents) { // if everything is default we don't need to bother with setup
			calendarVC.view;
			[calendarVC selectScrollerButton:[CalendarConstants titleForEventType:listType]];
		}
		
		if (!showList) {
			[self setupMapView:calendarVC queryDict:queryDict];
		}
		
		didHandle = YES;
		
	} else if ([path isEqualToString:CalendarStateCategoryList]) {
		// stack depth: 1 or 2
		
		// set up parent
		calendarVC.activeEventList = CalendarEventListTypeCategory;
		calendarVC.view;
		[calendarVC selectScrollerButton:[CalendarConstants titleForEventType:CalendarEventListTypeCategory]];
		if (queryDict == nil) {
			didHandle = YES;
			
		} else {
			// set up child
			NSString *catID = [queryDict objectForKey:@"catID"];
			if (catID != nil) {
				CalendarEventsViewController *childVC = [[CalendarEventsViewController alloc] init];

				childVC.catID = [catID intValue];
				childVC.activeEventList = CalendarEventListTypeCategory;
				childVC.showScroller = NO;
				[calendarVC.navigationController pushViewController:childVC animated:NO];
				[childVC release];
			
				didHandle = YES;
			}
		}
		
	} else if ([path isEqualToString:CalendarStateCategoryEventList]) {
		// stack depth: 2 or 3
		
		calendarVC.activeEventList = CalendarEventListTypeCategory;
		calendarVC.view;
		[calendarVC selectScrollerButton:[CalendarConstants titleForEventType:CalendarEventListTypeCategory]];
		
		NSString *catID = [queryDict objectForKey:@"catID"];
		if (catID != nil) {
			
			EventCategory *category = [CalendarDataManager categoryWithID:[catID intValue]];
			EventCategory *parentCategory = category.parentCategory;
			
            NSArray *subCategories = [parentCategory.subCategories allObjects];
			if ([subCategories count] > 1) {
				// set up subcategory view
				CalendarEventsViewController *subcatVC = [[CalendarEventsViewController alloc] init];
				subcatVC.activeEventList = CalendarEventListTypeCategory;
				subcatVC.catID = [catID intValue];
                ((EventCategoriesTableView *)subcatVC.tableView).categories = subCategories;
				subcatVC.showScroller = NO;
				subcatVC.navigationItem.title = parentCategory.title;
				[calendarVC.navigationController pushViewController:subcatVC animated:NO];			
				[subcatVC release];
			}
			
			// set up child
			CalendarEventsViewController *childVC = [[CalendarEventsViewController alloc] init];
			childVC.activeEventList = CalendarEventListTypeEvents;
			//childVC.events = [category.events allObjects];
            childVC.catID = [catID intValue];
			childVC.showList = showList;
			childVC.showScroller = NO;
			childVC.navigationItem.title = category.title;

			[calendarVC.navigationController pushViewController:childVC animated:NO];
			if (!showList) {
				[self setupMapView:childVC queryDict:queryDict];
			}
			[childVC release];
			
			didHandle = YES;
		}
		
	}
	
	return didHandle;
}

- (void)setupMapView:(CalendarEventsViewController *)calVC queryDict:(NSDictionary *)queryDict
{
	NSString *regionString = [queryDict objectForKey:@"region"];
	if (regionString != nil) {
		calVC.view;
		[calVC.mapView unserializeRegion:regionString];
	}
	
	NSString *eventIDString = [queryDict objectForKey:@"eventID"];
	if (eventIDString != nil) {
		NSInteger eventID = [eventIDString intValue];
		MITCalendarEvent *event = [CalendarDataManager eventWithID:eventID];
		calVC.view;
		calVC.mapView.shouldNotDropPins = YES;
		calVC.events = [calVC.events arrayByAddingObject:event];
		
		for (CalendarEventMapAnnotation *annotation in calVC.mapView.annotations) {
			if ([annotation.event.eventID intValue] == eventID) {
				[calVC.mapView selectAnnotation:annotation animated:NO withRecenter:NO];
				break;
			}
		}
	}
}

- (void)dealloc {
    [calendarVC release];
    [super dealloc];
}

@end

