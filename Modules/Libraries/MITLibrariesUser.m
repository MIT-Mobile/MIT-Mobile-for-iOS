#import "MITLibrariesUser.h"
#import "MITLibrariesWebservices.h"

@implementation MITLibrariesUser

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
