#import <Foundation/Foundation.h>

typedef void(^MITCalendarManagerCompletionBlock)(BOOL successful);


#import "MITCalendarsCalendar.h"
#import "MITCalendarsEvent.h"

@interface MITCalendarManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) MITCalendarsCalendar *eventsCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicHolidaysCalendar;
@property (nonatomic) BOOL calendarsLoaded;

- (void)loadCalendarsCompletion:(MITCalendarManagerCompletionBlock)completion;

@end
