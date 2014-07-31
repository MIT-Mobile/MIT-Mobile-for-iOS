#import <Foundation/Foundation.h>

typedef void(^MITCalendarManagerCompletionBlock)(BOOL successful);


@class MITCalendarsCalendar;
@class MITCalendarsEvent;

@interface MITCalendarManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) MITCalendarsCalendar *eventsCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicHolidaysCalendar;
@property (nonatomic) BOOL calendarsLoaded;

//@property (nonatomic, strong) NSArray *currentEvents;
//@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
//
- (void)loadCalendarsCompletion:(MITCalendarManagerCompletionBlock)completion;
//
//- (void)loadEventsForCalendar:(MITCalendarsCalendar *)calendar
//                   completion:(MITCalendarManagerCompletionBlock)completion;
//
//- (void)loadEentsForCalendar:(MITCalendarsCalendar *)calendar
//                        date:(NSDate *)date
//                  completion:(MITCalendarManagerCompletionBlock)completion;

@end
