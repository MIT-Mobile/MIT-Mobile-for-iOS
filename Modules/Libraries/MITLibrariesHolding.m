#import "MITLibrariesHolding.h"

@implementation MITLibrariesHolding

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesHolding class]];
    [mapping addAttributeMappingsFromDictionary:@{@"code" : @"code",
                                                  @"library" : @"library",
                                                  @"address" : @"address",
                                                  @"count" : @"count",
                                                  @"item_request_url" : @"requestUrl"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"availability" toKeyPath:@"availability" withMapping:[MITLibrariesAvailability objectMapping]]];
    return mapping;
}

@end
