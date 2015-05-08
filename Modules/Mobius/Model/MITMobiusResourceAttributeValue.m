#import "MITMobiusResourceAttributeValue.h"
#import "MITMobiusResourceAttributeValueSet.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusAttributeValue.h"


@implementation MITMobiusResourceAttributeValue

@dynamic value;
@dynamic valueSet;


- (NSString*)name
{
    NSOrderedSet *possibleAttributeValues = self.valueSet.attribute.values;
    NSInteger objectIndex = [possibleAttributeValues indexOfObjectPassingTest:^BOOL(MITMobiusAttributeValue *value, NSUInteger idx, BOOL *stop) {
        if ([value.value isEqualToString:self.value]) {
            return YES;
        } else {
            return NO;
        }
    }];

    NSString *name = nil;
    if (objectIndex != NSNotFound) {
        MITMobiusAttributeValue *value = possibleAttributeValues[objectIndex];
        name = value.text;
    }

    if (!name) {
        name = self.value;
    }

    return name;
}

@end
