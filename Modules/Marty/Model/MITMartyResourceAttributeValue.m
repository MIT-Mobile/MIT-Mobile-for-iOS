#import "MITMartyResourceAttributeValue.h"
#import "MITMartyResourceAttribute.h"


@implementation MITMartyResourceAttributeValue

@dynamic value;
@dynamic attribute;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    RKAttributeMapping *valueMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"value"];
    [mapping addPropertyMapping:valueMapping];

    return mapping;
}

@end
