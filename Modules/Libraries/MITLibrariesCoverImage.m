#import "MITLibrariesCoverImage.h"

@implementation MITLibrariesCoverImage

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
