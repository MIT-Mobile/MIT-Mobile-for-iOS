#import "MITLibrariesLink.h"

@implementation MITLibrariesLink

+ (RKMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesLink class]];
   
    [mapping addAttributeMappingsFromArray:@[@"title", @"url"]];
    
    return mapping;
}

@end
