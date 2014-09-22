#import "MITLibrariesLink.h"

@implementation MITLibrariesLink

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.title = dictionary[@"title"];
        self.url = dictionary[@"url"];
    }
    return self;
}

@end