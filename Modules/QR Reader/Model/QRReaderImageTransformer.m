#import "QRReaderImageTransformer.h"

@implementation QRReaderImageTransformer
+ (void)initialize
{
    [NSValueTransformer setValueTransformer:[[QRReaderImageTransformer alloc] init]
                                    forName:@"QRReaderImageTransformer"];
}

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
        UIImage *image = (UIImage*)value;
        return UIImagePNGRepresentation(image);
    }
}

- (id)reverseTransformedValue:(id)value {
    return [UIImage imageWithData:(NSData*)value];
}

@end
