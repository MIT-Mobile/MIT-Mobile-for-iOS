#import "MITLibrariesDate.h"

@implementation MITLibrariesDate

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesDate class]];
    
    [mapping addAttributeMappingsFromArray:@[@"start", @"end"]];
    
    return mapping;
}

@end
