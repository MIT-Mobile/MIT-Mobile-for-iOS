//
//  NSObject+JMIntrospection.h
//
//  Created by Logan Wright on 2/18/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JMIntrospection)

/**
 *  An array of the property names associated with the given class
 *
 *  @return array of property names
 */
- (NSArray *)jm_propertyNames;

/**
 *  Fetch class type
 *
 *  @param propertyName the property name to find a class for
 *
 *  @return the class associated with the given propertyName
 */
- (Class)jm_classForPropertyName:(NSString *)propertyName;

/**
 *
 *  @return An array of all available classes within the project
 */
+ (NSDictionary *)jm_swiftClassMapping;
@end
