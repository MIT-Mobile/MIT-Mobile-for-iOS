//
//  NSDateFormatter+RelativeString.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/13/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDateFormatter (RelativeString)
+ (NSString*)relativeDateStringFromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;
@end
