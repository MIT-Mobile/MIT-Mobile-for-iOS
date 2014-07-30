#import "MITCalendarsSeriesInfo.h"


@implementation MITCalendarsSeriesInfo

@dynamic title;
@dynamic seriesDescription;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"description": @"seriesDescription"}];
    [mapping addAttributeMappingsFromArray:@[@"title"]];
    
    [mapping setIdentificationAttributes:@[@"title", @"seriesDescription"]];
    
    return mapping;
}

@end
