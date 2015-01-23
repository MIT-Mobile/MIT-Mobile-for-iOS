#import "MITLibrariesUser.h"
#import "MITLibrariesWebservices.h"

@implementation MITLibrariesUser

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesUser class]];
    [mapping addAttributeMappingsFromDictionary:@{@"name" : @"name",
                                                  @"formatted_balance" : @"formattedBalance",
                                                  @"balance" : @"balance",
                                                  @"overdue_count" : @"overdueItemsCount",
                                                  @"ready_for_pickup_count" : @"readyForPickupCount"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"loans" toKeyPath:@"loans" withMapping:[MITLibrariesMITLoanItem objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"holds" toKeyPath:@"holds" withMapping:[MITLibrariesMITHoldItem objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"fines" toKeyPath:@"fines" withMapping:[MITLibrariesMITFineItem objectMapping]]];
    return mapping;
}

@end
