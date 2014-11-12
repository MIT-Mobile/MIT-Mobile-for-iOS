#import "MITLibrariesUser.h"
#import "MITLibrariesWebservices.h"

@implementation MITLibrariesUser

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesUser class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"name"] = @"name";
    attributeMappings[@"formatted_balance"] = @"formattedBalance";
    attributeMappings[@"balance"] = @"balance";
    attributeMappings[@"overdue_count"] = @"overdueItemsCount";
    attributeMappings[@"ready_for_pickup_count"] = @"readyForPickupCount";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"loans" toKeyPath:@"loans" withMapping:[MITLibrariesMITLoanItem objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"holds" toKeyPath:@"holds" withMapping:[MITLibrariesMITHoldItem objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"fines" toKeyPath:@"fines" withMapping:[MITLibrariesMITFineItem objectMapping]]];
    return mapping;
}

@end
