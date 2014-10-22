#import "MITToursLink.h"
#import "MITToursTour.h"

@implementation MITToursLink

@dynamic name;
@dynamic url;
@dynamic tour;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [mapping addAttributeMappingsFromArray:@[@"name", @"url"]];
    
    return mapping;
}

@end
