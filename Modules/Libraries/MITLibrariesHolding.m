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
        self.availability = [self parseAvailability:dictionary[@"availability"]];
    }
    return self;
}

- (NSArray *)parseAvailability:(NSArray *)JSONAvailability
{
    if (!JSONAvailability) {
        return nil;
    }
    
    NSMutableArray *availabilities = [[NSMutableArray alloc] init];
    for (NSDictionary *availableDictionary in JSONAvailability) {
        MITLibrariesAvailability *availability = [[MITLibrariesAvailability alloc] initWithDictionary:availableDictionary];
        [availabilities addObject:availability];
    }
    return availabilities;
}

@end
