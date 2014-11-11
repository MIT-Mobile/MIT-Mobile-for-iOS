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

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.width = [dictionary[@"width"] integerValue];
        self.height = [dictionary[@"height"] integerValue];
        self.url = dictionary[@"url"];
    }
    return self;
}

@end
