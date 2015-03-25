#import "MITMobiusResourceAttributeValue.h"
#import "MITMobiusResourceAttribute.h"


@implementation MITMobiusResourceAttributeValue

@dynamic value;
@dynamic attribute;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    RKAttributeMapping *valueMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"value"];
    [mapping addPropertyMapping:valueMapping];

    return mapping;
}

- (NSString *)value
{
    [self willAccessValueForKey:@"value"];
    NSString *value = [self primitiveValueForKey:@"value"];
    [self didAccessValueForKey:@"value"];
    
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return value;
}

@end
