#import <Foundation/Foundation.h>

typedef void(^MITCalendarsCompletionBlock)(NSArray *calendars, NSError *error);

@interface MITCalendarWebservices : NSObject

+ (void)getCalendarsWithCompletion:(MITCalendarsCompletionBlock)completion;

@end
