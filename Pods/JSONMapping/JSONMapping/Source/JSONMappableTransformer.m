//
//  JSONMappableTransformer.m
//
//  Created by Logan Wright on 2/18/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "JSONMappableTransformer.h"

@implementation JSONMappableTransformer
+ (id)transform:(id)fromVal {
    @throw [NSException exceptionWithName:@"Transform"
                                   reason:@"Must be overriden by subclass!"
                                 userInfo:nil];
}
@end
