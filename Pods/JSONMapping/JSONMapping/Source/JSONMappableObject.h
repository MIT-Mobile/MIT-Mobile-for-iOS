//
//  JSONMappableObject.h
//
//  Created by Logan Wright on 2/18/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JSONMappableObject <NSObject>

/**
 *  How to map the object with the format @{'propertyName' : 'associatedJSONKeyPath'}.  Also supports key paths, ie: @{'property.path' : 'associatedJSONKeyPath'}.  To map to arrays of a class, use @{'arrayPropertyName@JPTypeOfClass' : 'associatedJSONKeyPath'}.
 *
 *  @return the mapping defined by the user
 */
@required - (NSMutableDictionary *)mapping;

/**
 *  If nil or null is received from JSON for a given key, default values will be consulted before setting nil.
 *
 *  @return the default value for a given property name.  ie: @{'propertyName' : 'default value'} -- Supports key paths.
 *  @warning Do not use @ syntax to define a class in the default values section!
 */
@optional - (NSMutableDictionary *)defaultPropertyValues;

@end
