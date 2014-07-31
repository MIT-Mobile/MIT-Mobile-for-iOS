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
                                                    if (result.array) {
                                                        completion(result.array, nil);
                                                    }
                                                    else {
                                                        completion(nil, error);
                                                    }
                                                }];
}

+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                        date:(NSDate *)date
                  completion:(MITEventsCompletionBlock)completion
{

    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITCalendarEventsResourceName
                                                    object:@{@"calendar" : calendar.identifier}
                                                parameters:@{@"category" : @"19"}
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    NSLog(@"results: %@", result.array);
                                                    if (result.array) {
                                                        completion(result.array, nil);
                                                    }
                                                    else {
                                                        completion(nil, error);
                                                    }
                                                }];
}

@end
