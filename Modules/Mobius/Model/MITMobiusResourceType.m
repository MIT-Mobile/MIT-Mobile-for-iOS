#import "MITMobiusResourceType.h"


@implementation MITMobiusResourceType

@dynamic identifier;
@dynamic type;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *roomsetMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [roomsetMapping addAttributeMappingsFromDictionary:@{@"_id" : @"identifier",
                                                         @"type" : @"type"}];
    return roomsetMapping;
}

@end
