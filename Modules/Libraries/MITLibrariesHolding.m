#import "MITLibrariesHolding.h"

@implementation MITLibrariesHolding

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesHolding class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"code"] = @"code";
    attributeMappings[@"library"] = @"library";
    attributeMappings[@"address"] = @"address";
    attributeMappings[@"count"] = @"count";
    attributeMappings[@"item_request_url"] = @"requestUrl";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"availability" toKeyPath:@"availability" withMapping:[MITLibrariesAvailability objectMapping]]];
    return mapping;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.code = dictionary[@"code"];
        self.library = dictionary[@"library"];
        self.address = dictionary[@"address"];
        self.count = [dictionary[@"count"] integerValue];
        self.requestUrl = dictionary[@"item_request_url"];
        self.availability = [MITLibrariesWebservices parseJSONArray:dictionary[@"availability"] intoObjectsOfClass:[MITLibrariesAvailability class]];
    }
    return self;
}

@end
