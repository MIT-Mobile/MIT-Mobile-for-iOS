//
//  MealReference.h
//  MIT Mobile
//
//  Created by Austin Emmons on 6/3/13.
//
//

#import <Foundation/Foundation.h>

@interface MealReference : NSObject

@property (nonatomic, strong) NSString  * name;
@property (nonatomic, strong) NSDate    * date;

+ (MealReference *) referenceWithMealName:(NSString *)name onDate:(NSDate *)date;

@end
