#import "MITMobiusAttributeValue.h"
#import "MITMobiusAttribute.h"

@implementation MITMobiusAttributeValue

@dynamic value;
@dynamic text;
@dynamic attribute;
@dynamic searchOptions;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [mapping addAttributeMappingsFromDictionary:@{@"text" : @"text",
                                                  @"value" : @"value"}];

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
