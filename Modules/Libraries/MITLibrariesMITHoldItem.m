#import "MITLibrariesMITHoldItem.h"

@implementation MITLibrariesMITHoldItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITHoldItem class]];
    NSDictionary *superMappings = [super attributeMappings];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionaryWithDictionary:superMappings];
    attributeMappings[@"status"] = @"status";
    attributeMappings[@"pickup_location"] = @"pickupLocation";
    attributeMappings[@"ready_for_pickup"] = @"readyForPickup";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    
    for (RKRelationshipMapping *relationshipMapping in [super relationshipMappings]) {
        [mapping addPropertyMapping:relationshipMapping];
    }
    
    return mapping;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.status = dictionary[@"status"];
        self.pickupLocation = dictionary[@"pickup_location"];
        self.readyForPickup = [dictionary[@"ready_for_pickup"] boolValue];
    }
    return self;
}

@end
