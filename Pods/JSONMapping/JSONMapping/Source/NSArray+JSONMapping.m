//
//  NSArray+JSONMapping.m
//
//  Created by Logan Wright on 2/18/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "NSArray+JSONMapping.h"
#import "NSObject+JSONMapping.h"
#import "JSONMappableObject.h"

@implementation NSArray (JSONMapping)
- (NSArray *)jm_mapToJSONMappableClass:(Class)classForMap {
    [self assertClassIsMappable:classForMap];
    
    NSMutableArray *mapped = [NSMutableArray array];
    for (NSDictionary *rawObject in self) {
        id mappedObject = [[classForMap alloc] initWithJSONRepresentation:rawObject];
        [mapped addObject:mappedObject];
    }
    return [NSArray arrayWithArray:mapped];
}

- (void)assertClassIsMappable:(Class)classForMap {
    BOOL isJsonMappable = [classForMap conformsToProtocol:@protocol(JSONMappableObject)];
    NSString *assertionMsg = @"This method requires a class that conforms to JSONMappableObject!";
    NSAssert(isJsonMappable, assertionMsg);
}

@end
