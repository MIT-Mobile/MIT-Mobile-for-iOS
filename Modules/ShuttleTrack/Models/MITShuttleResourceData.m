#import "MITShuttleResourceData.h"

const NSInteger kResourceSectionCount = 2;

NSString * const kResourceDescriptionKey = @"description";
NSString * const kResourcePhoneNumberKey = @"phoneNumber";
NSString * const kResourceFormattedPhoneNumberKey = @"formattedPhoneNumber";
NSString * const kResourceURLKey = @"url";

NSString * const kContactInformationHeaderTitle = @"Contact Information";
NSString * const kMBTAInformationHeaderTitle = @"MBTA Information";

@implementation MITShuttleResourceData

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupResourceData];
    }
    return self;
}

- (void)setupResourceData
{
    // TODO: these phone numbers and links should be provided by the server, not hardcoded
	self.contactInformation = @[
                                @{kResourceDescriptionKey:          @"Parking Office",
                                  kResourcePhoneNumberKey:          @"16172586510",
                                  kResourceFormattedPhoneNumberKey: @"617.258.6510"},
                                @{kResourceDescriptionKey:          @"Saferide",
                                  kResourcePhoneNumberKey:          @"16172532997",
                                  kResourceFormattedPhoneNumberKey: @"617.253.2997"}
                                ];
	
    self.mbtaInformation = @[
                             @{kResourceDescriptionKey: @"Real-time Bus Arrivals",
                               kResourceURLKey:         @"http://www.nextbus.com/webkit"},
                             @{kResourceDescriptionKey: @"Real-time Train Arrivals",
                               kResourceURLKey:         @"http://www.mbtainfo.com/"},
                             @{kResourceDescriptionKey: @"Google Transit",
                               kResourceURLKey:         @"http://www.google.com/transit"}
                             ];
}

@end
