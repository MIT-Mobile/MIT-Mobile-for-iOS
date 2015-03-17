#import "MITMobiusResourceOwner.h"
#import "MITMobiusResource.h"


@implementation MITMobiusResourceOwner

@dynamic name;
@dynamic resource;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *resourceOwnerMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"name"];
    [resourceOwnerMapping addPropertyMapping:nameMapping];

    return resourceOwnerMapping;
}

@end
