#import "MITLibrariesCoverImage.h"

@implementation MITLibrariesCoverImage

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesCoverImage class]];
    [mapping addAttributeMappingsFromDictionary:@{@"width" : @"width",
                                                  @"height" : @"height",
                                                  @"url" : @"url"}];
    return mapping;
}

@end
