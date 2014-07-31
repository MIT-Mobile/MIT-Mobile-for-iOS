#import "MITCalendarWebservices.h"
#import <RestKit/RestKit.h>
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"

#import "MITCalendarsCalendar.h"


@implementation MITCalendarWebservices

+(void)getCalendarsWithCompletion:(MITCalendarsCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITCalendarsResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    NSLog(@"Result: %@", result);
                                                }];

}


@end
