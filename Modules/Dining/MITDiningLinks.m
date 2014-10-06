#import "MITDiningLinks.h"
#import "MITDiningDining.h"

@implementation MITDiningLinks

@dynamic name;
@dynamic url;
@dynamic dining;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"url"]];
    
    return mapping;
}

@end
