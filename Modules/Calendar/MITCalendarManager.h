#import <Foundation/Foundation.h>
#import "MITCalendarsCalendar.h"
#import "MITCalendarsEvent.h"
#import "MITMasterCalendar.h"

typedef void(^MITCalendarManagerCompletionBlock)(MITMasterCalendar *masterCalendar,
                                                 NSError *error);

@interface MITCalendarManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

- (void)getCalendarsCompletion:(MITCalendarManagerCompletionBlock)completion;

@end
