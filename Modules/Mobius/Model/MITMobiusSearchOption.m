#import "MITMobiusSearchOption.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusAttributeValue.h"
#import "MITMobiusRecentSearchQuery.h"


@implementation MITMobiusSearchOption

@dynamic value;
@dynamic values;
@dynamic query;
@dynamic attribute;

- (NSString*)value {
    [self willAccessValueForKey:@"value"];
    NSString *value = [self primitiveValueForKey:@"value"];
    [self didAccessValueForKey:value];

    if (!value) {
        NSMutableArray *values = [[NSMutableArray alloc] init];
        [self.values enumerateObjectsUsingBlock:^(MITMobiusAttributeValue *attributeValue, NSUInteger idx, BOOL *stop) {
            [values addObject:attributeValue.text];
        }];

        value = [values componentsJoinedByString:@","];
    }

    return value;
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error
{
    BOOL result = [super validateForUpdate:error];

    __block BOOL localResult = YES;
    [self.values enumerateObjectsUsingBlock:^(MITMobiusAttributeValue *attributeValue, NSUInteger idx, BOOL *stop) {
        localResult = localResult && [attributeValue.attribute isEqual:self.attribute];

        (*stop) = localResult;
    }];

    return localResult && result;
}

@end
