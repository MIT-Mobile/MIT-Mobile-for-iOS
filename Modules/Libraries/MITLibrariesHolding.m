#import "MITLibrariesHolding.h"

@implementation MITLibrariesHolding

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.code = dictionary[@"code"];
        self.library = dictionary[@"library"];
        self.address = dictionary[@"address"];
        self.count = [dictionary[@"count"] integerValue];
        self.url = dictionary[@"url"];
        self.availability = [MITLibrariesWebservices parseJSONArray:dictionary[@"availability"] intoObjectsOfClass:[MITLibrariesAvailability class]];
    }
    return self;
}

@end
