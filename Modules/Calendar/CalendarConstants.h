#import <Foundation/Foundation.h>

#define kCalendarTopLevelCategoryID -1
#define kCalendarAcademicCategoryID 15897
#define kCalendarHolidayCategoryID 23786

#define kCalendarEventTimeoutSeconds 900

typedef enum {
	CalendarEventListTypeEvents,
	CalendarEventListTypeExhibits,
	CalendarEventListTypeCategory,
	CalendarEventListTypeAcademic,
	CalendarEventListTypeHoliday,
	NumberOfCalendarEventListTypes
} CalendarEventListType;

// strings for tracking state

extern NSString * const CalendarStateEventList; // selected list type on home screen
extern NSString * const CalendarStateCategoryList; // top-level or subcategories
extern NSString * const CalendarStateCategoryEventList; // event list within one category
//extern NSString * const CalendarStateSearchHome;
//extern NSString * const CalendarStateSearchResults;
extern NSString * const CalendarStateEventDetail;


// server API parameters to expose to other files
extern NSString * const CalendarEventAPISearch;

@interface CalendarConstants : NSObject {

}

+ (NSString *)apiCommandForEventType:(CalendarEventListType)listType;
+ (NSString *)titleForEventType:(CalendarEventListType)listType;
+ (NSTimeInterval)intervalForEventType:(CalendarEventListType)listType fromDate:(NSDate *)aDate forward:(BOOL)forward;
+ (NSString *)dateStringForEventType:(CalendarEventListType)listType forDate:(NSDate *)aDate;

@end
