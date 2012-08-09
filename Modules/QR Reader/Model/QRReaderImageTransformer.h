#import <Foundation/Foundation.h>

@interface QRReaderImageTransformer : NSValueTransformer
+ (BOOL)allowsReverseTransformation;
+ (Class)transformedValueClass;

- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;
@end
