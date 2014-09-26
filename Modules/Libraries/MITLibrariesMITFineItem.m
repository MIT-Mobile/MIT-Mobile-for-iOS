#import "MITLibrariesMITFineItem.h"

@implementation MITLibrariesMITFineItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.status = dictionary[@"status"];
        self.fineDescription = dictionary[@"description"];
        self.formattedAmount = dictionary[@"formatted_amount"];
        self.amount = [dictionary[@"amount"] integerValue];
        self.finedAtDate = [[MITLibrariesWebservices librariesDateFormatter] dateFromString:dictionary[@"fined_at"]];
    }
    return self;
}

@end
