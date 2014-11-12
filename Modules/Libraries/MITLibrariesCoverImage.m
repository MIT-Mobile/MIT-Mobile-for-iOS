#import "MITLibrariesCoverImage.h"

@implementation MITLibrariesCoverImage

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesCoverImage class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"width"] = @"width";
    attributeMappings[@"height"] = @"height";
    attributeMappings[@"url"] = @"url";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    return mapping;
}

@end
