
#import "MealReference.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

@implementation MealReference

+ (MealReference *) referenceWithMealName:(NSString *)name onDate:(NSDate *)date
{
    MealReference *ref = [[MealReference alloc] init];
    ref.name = name;
    ref.date = date;
    
    return ref;
}

+ (DiningMeal *) mealForReference:(MealReference *)reference atVenueWithShortName:(NSString *)venueShortName
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@ AND startTime >= %@ AND endTime <= %@ AND day.houseVenue.shortName == %@", reference.name, [reference.date startOfDay], [reference.date endOfDay], venueShortName];
    NSArray *results = [CoreDataManager objectsForEntity:@"DiningMeal" matchingPredicate:pred];
    return [results lastObject];    // should never be more than 1 result (name is unique for a particular date)
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@:%p name:\"%@\" date:%@", [self class], self, self.name, self.date];
}

@end
