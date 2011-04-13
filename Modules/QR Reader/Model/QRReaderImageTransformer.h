//
//  QRReaderImageTransformer.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/13/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface QRReaderImageTransformer : NSValueTransformer {
    
}
+ (BOOL)allowsReverseTransformation;
+ (Class)transformedValueClass;

- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;
@end
