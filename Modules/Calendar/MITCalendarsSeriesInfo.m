#import "MITCalendarsSeriesInfo.h"
#import "MITCalendarsEvent.h"

@implementation MITCalendarsSeriesInfo

@dynamic seriesDescription;
@dynamic title;
@dynamic event;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"description": @"seriesDescription"}];
    [mapping addAttributeMappingsFromArray:@[@"title"]];
    
    [mapping setIdentificationAttributes:@[@"title", @"seriesDescription"]];
    
    return mapping;
}

@end