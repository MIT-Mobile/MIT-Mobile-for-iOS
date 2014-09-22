#import "MITLibrariesItem.h"

@implementation MITLibrariesItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.identifier = dictionary[@"id"];
        self.url = dictionary[@"url"];
        self.title = dictionary[@"title"];
        self.imageUrl = dictionary[@"image"];
        self.author = dictionary[@"author"];
        self.year = dictionary[@"year"];
        self.publisher = dictionary[@"publisher"];
    }
    return self;
}

@end
