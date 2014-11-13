#import "MITLibrariesAvailability.h"

@implementation MITLibrariesAvailability

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesAvailability class]];
    [mapping addAttributeMappingsFromDictionary:@{@"location" : @"location",
                                                  @"collection" : @"collection",
                                                  @"call_number" : @"callNumber",
                                                  @"status" : @"status",
                                                  @"available" : @"available"}];
    return mapping;
}

@end
