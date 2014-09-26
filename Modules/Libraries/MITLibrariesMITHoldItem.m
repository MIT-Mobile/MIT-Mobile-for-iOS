#import "MITLibrariesMITHoldItem.h"

@implementation MITLibrariesMITHoldItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.status = dictionary[@"status"];
        self.pickupLocation = dictionary[@"pickup_location"];
    }
    return self;
}

@end
