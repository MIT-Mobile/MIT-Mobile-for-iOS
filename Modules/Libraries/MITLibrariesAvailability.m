#import "MITLibrariesAvailability.h"

@implementation MITLibrariesAvailability
+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesAvailability class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"location"] = @"location";
    attributeMappings[@"collection"] = @"collection";
    attributeMappings[@"call_number"] = @"callNumber";
    attributeMappings[@"status"] = @"status";
    attributeMappings[@"available"] = @"available";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    return mapping;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.location = dictionary[@"location"];
        self.collection = dictionary[@"collection"];
        self.callNumber = dictionary[@"call_number"];
        self.status = dictionary[@"status"];
        self.available = [dictionary[@"available"] boolValue];
    }
    return self;
}

@end
