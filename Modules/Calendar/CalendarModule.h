#import <Foundation/Foundation.h>
#import "MITModule.h"

@class CalendarEventsViewController;

@interface CalendarModule : MITModule {

	CalendarEventsViewController *calendarVC;
	
}

@property (nonatomic, retain) CalendarEventsViewController *calendarVC;

@end

