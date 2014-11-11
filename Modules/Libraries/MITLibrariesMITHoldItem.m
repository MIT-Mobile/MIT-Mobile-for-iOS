#import "MITLibrariesMITHoldItem.h"

@implementation MITLibrariesMITHoldItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITHoldItem class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"status"] = @"status";
    attributeMappings[@"pickup_location"] = @"pickupLocation";
    attributeMappings[@"ready_for_pickup"] = @"readyForPickup";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
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
