#import <Foundation/Foundation.h>
#import "MITCalendarEvent.h"
#import "EventCategory.h"

#define kCalendarTopLevelCategoryID -1
#define kCalendarEventTimeoutSeconds 900

// strings for handleLocalPath

extern NSString * const CalendarStateEventList; // selected list type on home screen
extern NSString * const CalendarStateCategoryList; // top-level or subcategories
extern NSString * const CalendarStateCategoryEventList; // event list within one category
//extern NSString * const CalendarStateSearchHome;
//extern NSString * const CalendarStateSearchResults;
extern NSString * const CalendarStateEventDetail;

// server API parameters
extern NSString * const CalendarEventAPISearch;

@protocol CalendarDataManagerDelegate;
@class MITEventList;

@interface CalendarDataManager : NSObject
@property (weak) id<CalendarDataManagerDelegate> delegate;

+ (CalendarDataManager *)sharedManager;
- (NSArray *)eventLists;
- (NSArray *)staticEventListIDs;
- (MITEventList *)eventListWithID:(NSString *)listID; // grabs from memory
- (BOOL)isDailyEvent:(MITEventList *)listType;

- (void)requestEventLists;

// delete after open house is done
- (void)makeOpenHouseCategoriesRequest;
- (NSString *)getOpenHouseCatIdWithIdentifier:(NSString *)identifier;

+ (MITEventList *)eventListWithID:(NSString *)listID; // grabs from core data
+ (NSArray *)eventsWithStartDate:(NSDate *)startDate listType:(MITEventList *)listType category:(NSNumber *)catID;
+ (EventCategory *)categoryWithName:(NSString *)categoryName;
+ (EventCategory *)categoryForExhibits;

+ (NSArray *)topLevelCategories;
+ (NSArray *)openHouseCategories;
+ (EventCategory *)categoryWithID:(NSInteger)catID forListID:(NSString *)listID;
+ (MITCalendarEvent *)eventWithID:(NSInteger)eventID;
+ (MITCalendarEvent *)eventWithDict:(NSDictionary *)dict;
+ (EventCategory *)categoryWithDict:(NSDictionary *)dict forListID:(NSString *)listID;
+ (void)pruneOldEvents;

+ (NSString *)apiCommandForEventType:(MITEventList *)listType;
+ (NSTimeInterval)intervalForEventType:(MITEventList *)listType fromDate:(NSDate *)aDate forward:(BOOL)forward;
+ (NSString *)dateStringForEventType:(MITEventList *)listType forDate:(NSDate *)aDate;

@end


@protocol CalendarDataManagerDelegate <NSObject>

- (void)calendarListsLoaded;
- (void)calendarListsFailedToLoad;

@end
