#import "MITMobiusResourceDLC.h"
#import "MITMobiusResource.h"


@implementation MITMobiusResourceDLC

@dynamic code;
@dynamic name;
@dynamic resource;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *objectMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [objectMapping addAttributeMappingsFromDictionary:@{@"_id" : @"identifier",
                                                        @"dlc_name" : @"name",
                                                        @"dlc_code" : @"code"}];

    return objectMapping;
}

@end
