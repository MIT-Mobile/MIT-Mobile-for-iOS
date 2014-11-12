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

@end
