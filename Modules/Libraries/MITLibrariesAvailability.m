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

@end
