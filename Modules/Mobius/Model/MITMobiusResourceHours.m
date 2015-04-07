#import "MITMobiusResourceHours.h"
#import "MITMobiusResource.h"


@implementation MITMobiusResourceHours

@dynamic startDate;
@dynamic endDate;
@dynamic resource;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *hoursMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [hoursMapping addAttributeMappingsFromDictionary:@{@"start_date" : @"startDate",
                                                       @"end_date" : @"endDate"}];
    return hoursMapping;
}

@end
