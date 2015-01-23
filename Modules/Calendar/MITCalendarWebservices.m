#import "MITCalendarWebservices.h"
#import <RestKit/RestKit.h>
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"
#import "Foundation+MITAdditions.h"

#import "MITCalendarsCalendar.h"

typedef void(^MITCalendarCompletionBlock)(id object, NSError *error);

@implementation MITCalendarWebservices

+ (void)getCalendarsWithCompletion:(MITCalendarsCompletionBlock)completion
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
                  completion:(MITEventsCompletionBlock)completion
{
    [MITCalendarWebservices getEventsForCalendar:calendar queryString:nil category:nil startDate:nil endDate:nil completion:completion];
}

+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                        date:(NSDate *)date
                  completion:(MITEventsCompletionBlock)completion
{
    [MITCalendarWebservices getEventsForCalendar:calendar queryString:nil category:nil startDate:date endDate:[date endOfDay] completion:completion];
}

+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                     category:(MITCalendarsCalendar *)category
                        date:(NSDate *)date
                  completion:(MITEventsCompletionBlock)completion
{
    [MITCalendarWebservices getEventsForCalendar:calendar queryString:nil category:category startDate:date endDate:[date endOfDay] completion:completion];
}

+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                 queryString:(NSString *)queryString
                    category:(MITCalendarsCalendar *)category
                   startDate:(NSDate *)startDate
                     endDate:(NSDate *)endDate
                  completion:(MITEventsCompletionBlock)completion
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (queryString){
        [params setObject:queryString forKey:@"q"];
    }
    if (category) {
        [params setObject:category.identifier forKey:@"category"];
    }
    if (startDate) {
        [params setObject:[dateFormatter stringFromDate:startDate] forKey:@"start"];
    }
    if (endDate) {
        [params setObject:[dateFormatter stringFromDate:endDate] forKey:@"end"];
    }
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITCalendarEventsResourceName
                                                    object:@{@"calendar" : calendar.identifier}
                                                parameters:params
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [MITCalendarWebservices handleResult:result error:error completion:completion];
                                                }];
}

+ (void)handleResult:(RKMappingResult *)result error:(NSError *)error completion:(MITCalendarCompletionBlock)completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!error) {
            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
            NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
            if (completion) {
                completion(objects, nil);
            }
        } else {
            if (completion) {
                completion(nil, error);
            }
        }
    }];
}

+ (void)getEventsWithinOneMonthInCalendar:(MITCalendarsCalendar *)calendar category:(MITCalendarsCalendar *)category forQuery:(NSString *)query completion:(MITEventsCompletionBlock)completion
{
    // Per webservice documentation, the default end date is 1 month from the current date
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:query forKey:@"q"];
    
    if (category) {
        [params setObject:category.identifier forKey:@"category"];
    }
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITCalendarEventsResourceName object:@{@"calendar": calendar.identifier} parameters:params completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(result.array, nil);
        }
    }];
}

+ (void)getEventsWithinOneYearInCalendar:(MITCalendarsCalendar *)calendar category:(MITCalendarsCalendar *)category forQuery:(NSString *)query completion:(MITEventsCompletionBlock)completion
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:query forKey:@"q"];
    
    if (category) {
        [params setObject:category.identifier forKey:@"category"];
    }
    
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.year = 1;
    NSDate *oneYearFromNow = [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:[NSDate date] options:0];
    [params setObject:[oneYearFromNow ISO8601String] forKey:@"end"];
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITCalendarEventsResourceName object:@{@"calendar": calendar.identifier} parameters:params completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(result.array, nil);
        }
    }];
}

+ (void) getEventDetailsForEventURL:(NSURL *)eventURL withCompletion:(MITEventDetailCompletionBLock)completion
{
    [[MITMobile defaultManager] getObjectsForURL:eventURL completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        if (result.array.firstObject) {
            completion(result.array.firstObject, nil);
        } else {
            completion(nil, error);
        }
    }];
}

@end
