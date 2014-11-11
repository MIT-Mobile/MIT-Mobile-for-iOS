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

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.name = dictionary[@"name"];
        self.loans = [MITLibrariesWebservices parseJSONArray:dictionary[@"loans"] intoObjectsOfClass:[MITLibrariesMITLoanItem class]];
        self.holds = [MITLibrariesWebservices parseJSONArray:dictionary[@"holds"] intoObjectsOfClass:[MITLibrariesMITHoldItem class]];
        self.fines = [MITLibrariesWebservices parseJSONArray:dictionary[@"fines"] intoObjectsOfClass:[MITLibrariesMITFineItem class]];
        self.formattedBalance = dictionary[@"formatted_balance"];
        self.balance = [dictionary[@"balance"] integerValue];
        self.overdueItemsCount = [dictionary[@"overdue_count"] integerValue];
        self.readyForPickupCount = [dictionary[@"ready_for_pickup_count"] integerValue];
    }
    return self;
}

@end
