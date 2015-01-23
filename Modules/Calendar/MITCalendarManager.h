#import <Foundation/Foundation.h>
#import "MITCalendarsCalendar.h"
#import "MITCalendarsEvent.h"
#import "MITMasterCalendar.h"

typedef void(^MITMasterCalendarCompletionBlock)(MITMasterCalendar *masterCalendar,
                                                 NSError *error);
typedef void(^MITCachedEventsCompletionBlock)(NSArray *events,
                                                NSError *error);

@interface MITCalendarManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

- (void)getCalendarsCompletion:(MITMasterCalendarCompletionBlock)completion;

@end
