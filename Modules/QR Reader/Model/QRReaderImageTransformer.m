//
//  QRReaderImageTransformer.m
//  MIT Mobile
//
//  Created by Blake Skinner on 4/13/11.
//  Copyright 2011 MIT. All rights reserved.
//

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
