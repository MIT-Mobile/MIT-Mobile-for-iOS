#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "MITModuleURL.h"
#import "MITMobileWebAPI.h"
#import "CalendarEventMapAnnotation.h"
#import <MapKit/MapKit.h>
#import "MITEventList.h"
#import "OpenHouseTableView.h"

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
        
        //calendarVC = [[CalendarEventsViewController alloc] init];
		//calendarVC.activeEventList = CalendarEventListTypeEvents;
		//calendarVC.showList = YES;
		//calendarVC.showScroller = YES;
        //[self.tabNavController setViewControllers:[NSArray arrayWithObject:calendarVC]];
    }
    return self;
}

- (UIViewController *)moduleHomeController {
    if (!calendarVC) {
        calendarVC = [[CalendarEventsViewController alloc] init];
        calendarVC.showList = YES;
        calendarVC.showScroller = YES;
    }
    return calendarVC;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
	BOOL didHandle = NO;
	
	NSArray *pathComponents = [localPath componentsSeparatedByString:@"/"];
	NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pathComponent in pathComponents) {
        if ([pathComponent isEqualToString:CalendarStateCategoryEventList]) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            for (NSString *queryComponent in queryComponents) {
                NSArray *queryParts = [queryComponent componentsSeparatedByString:@"="];
                if ([queryParts count] == 2) {
                    [params setObject:[queryParts objectAtIndex:1] forKey:[queryParts objectAtIndex:0]];
                }
            }
             
            if ([params objectForKey:@"catID"]) {
                    
                [self popToRootViewController];

                self.moduleHomeController.view;
                
                NSNumber *catID = [params objectForKey:@"catID"];
                NSString *listID = [params objectForKey:@"listID"];
                CalendarEventsViewController *childVC = [[[CalendarEventsViewController alloc] init] autorelease];
                EventCategory *category = [CalendarDataManager categoryWithID:[catID intValue] forListID:listID];
                childVC.category = category;
                childVC.showScroller = NO;
                childVC.navigationItem.title = category.title;
                
                if(!listID) {
                    [calendarVC selectScrollerButton:@"Categories"];
                    MITEventList *eventList = [[CalendarDataManager sharedManager] eventListWithID:@"categories"];
                    childVC.events = [CalendarDataManager eventsWithStartDate:calendarVC.startDate listType:eventList category:catID];
                } else if([listID isEqualToString:@"OpenHouse"]) {
                    [calendarVC selectScrollerButton:@"Open House"];
                    childVC.events = [category.events allObjects];
                    childVC.startDate = [NSDate dateWithTimeIntervalSince1970:OPEN_HOUSE_START_DATE];
                }
                
                [self.moduleHomeController.navigationController pushViewController:childVC animated:NO];
                
                [self becomeActiveTab];
            }
        }
    }
    
    for (NSString *queryComponent in queryComponents) {
        NSArray *queryParts = [queryComponent componentsSeparatedByString:@"="];
        if ([queryParts count] == 2) {
            if ([[queryParts objectAtIndex:0] isEqualToString:@"source"]) {
                NSString *buttonTitle = [queryParts objectAtIndex:1];
                self.moduleHomeController.view;
                [(CalendarEventsViewController *)self.moduleHomeController selectScrollerButton:buttonTitle];
                [self becomeActiveTab];
                didHandle = YES;
            }
        }
    }
	
	return didHandle;
}

- (void)dealloc {
    [calendarVC release];
    [super dealloc];
}

@end

