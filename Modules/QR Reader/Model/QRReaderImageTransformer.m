#import "QRReaderImageTransformer.h"


@implementation QRReaderImageTransformer
+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass {
    return [NSData class];
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    } else if ([value isKindOfClass:[NSData class]]) {
        return value;
    } else {
        return UIImagePNGRepresentation((UIImage*)value);
    }
}

- (id)reverseTransformedValue:(id)value {
    return [UIImage imageWithData:value];
}

@end
