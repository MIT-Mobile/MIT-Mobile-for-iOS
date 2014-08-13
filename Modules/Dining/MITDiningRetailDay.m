#import "MITDiningRetailDay.h"

@implementation MITDiningRetailDay

@dynamic date;
@dynamic endTime;
@dynamic message;
@dynamic startTime;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"start_time" : @"startTime",
                                                  @"end_time" : @"endTime"}];
    [mapping addAttributeMappingsFromArray:@[@"date", @"message"]];
    
    return mapping;
}

@end
