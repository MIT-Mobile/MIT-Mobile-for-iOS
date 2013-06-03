//
//  MealReference.m
//  MIT Mobile
//
//  Created by Austin Emmons on 6/3/13.
//
//

#import "MealReference.h"

@implementation MealReference

+ (MealReference *) referenceWithMealName:(NSString *)name onDate:(NSDate *)date
{
    MealReference *ref = [[MealReference alloc] init];
    ref.name = name;
    ref.date = date;
    
    return ref;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@:%p name:\"%@\" date:%@", [self class], self, self.name, self.date];
}

@end
