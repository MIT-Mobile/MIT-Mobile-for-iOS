#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "MITModuleURL.h"
#import "MITMobileWebAPI.h"
#import "CalendarEventMapAnnotation.h"
#import <MapKit/MapKit.h>
#import "MITEventList.h"

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
            for (NSString *queryComponent in queryComponents) {
                NSArray *queryParts = [queryComponent componentsSeparatedByString:@"="];
                if ([queryParts count] == 2) {
                    if ([[queryParts objectAtIndex:0] isEqualToString:@"catID"]) {
                        [self popToRootViewController];

                        self.moduleHomeController.view;
                        [calendarVC selectScrollerButton:@"Categories"];

                        NSInteger catID = [[queryParts objectAtIndex:1] integerValue];
                        CalendarEventsViewController *childVC = [[[CalendarEventsViewController alloc] init] autorelease];
                        MITEventList *eventList = [[CalendarDataManager sharedManager] eventListWithID:@"categories"];
                        childVC.catID = catID;
                        childVC.events = [CalendarDataManager eventsWithStartDate:calendarVC.startDate listType:eventList category:[NSNumber numberWithInt:catID]];
                        childVC.showScroller = NO;
                        
                        EventCategory *category = [CalendarDataManager categoryWithID:catID];
                        childVC.navigationItem.title = category.title;

                        [self.moduleHomeController.navigationController pushViewController:childVC animated:NO];
                        
                        [self becomeActiveTab];
                        didHandle = YES;
                    }
                }
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

