#import "DiningDietaryFlag.h"
#import "DiningMealItem.h"
#import "CoreDataManager.h"

@implementation DiningDietaryFlag

@dynamic name;
@dynamic items;

+ (DiningDietaryFlag *)flagWithName:(NSString *)name {
    DiningDietaryFlag *flag = [CoreDataManager getObjectForEntity:@"DiningDietaryFlag" attribute:@"name" value:name];
    if (!flag) {
        flag = [CoreDataManager insertNewObjectForEntityForName:@"DiningDietaryFlag"];
        flag.name = name;
    }
    return flag;
}

- (NSString *)description {
    return self.name;
}

@end
