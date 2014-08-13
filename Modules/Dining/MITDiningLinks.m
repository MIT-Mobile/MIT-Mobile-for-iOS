#import "MITDiningLinks.h"

@implementation MITDiningLinks

@dynamic name;
@dynamic url;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"url"]];
    
    return mapping;
}

@end
