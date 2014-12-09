#import "MITLibrariesMITHoldItem.h"

@implementation MITLibrariesMITHoldItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITHoldItem class]];
    NSMutableDictionary *superMappings = [[super attributeMappings] mutableCopy];
    [superMappings addEntriesFromDictionary:@{@"status" : @"status",
                                             @"pickup_location" : @"pickupLocation",
                                              @"ready_for_pickup" : @"readyForPickup"}];
    [mapping addAttributeMappingsFromDictionary:superMappings];
    
    for (RKRelationshipMapping *relationshipMapping in [super relationshipMappings]) {
        [mapping addPropertyMapping:relationshipMapping];
    }
    
    return mapping;
}

@end
