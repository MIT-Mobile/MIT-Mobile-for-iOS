#import "MITMobiusRoomSet.h"
#import "MITMobiusResource.h"


@implementation MITMobiusRoomSet

@dynamic code;
@dynamic identifier;
@dynamic name;
@dynamic resources;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *roomsetMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [roomsetMapping addAttributeMappingsFromDictionary:@{@"_id" : @"identifier",
                                                         @"roomset_code" : @"code",
                                                         @"roomset_name" : @"name"}];
    return roomsetMapping;
}

@end
