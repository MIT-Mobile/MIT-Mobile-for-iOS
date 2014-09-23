#import "MITLibrariesAvailability.h"

@implementation MITLibrariesAvailability

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.location = dictionary[@"location"];
        self.collection = dictionary[@"collection"];
        self.callNumber = dictionary[@"call-no"];
        self.status = dictionary[@"status"];
        self.available = [dictionary[@"available"] boolValue];
    }
    return self;
}

@end
