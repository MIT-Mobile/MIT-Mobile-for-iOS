#import "DiningMealItem.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"

@implementation DiningMealItem

@dynamic name;
@dynamic subtitle;
@dynamic station;
@dynamic meal;
@dynamic dietaryFlags;
@dynamic ordinality;

+ (DiningMealItem *)newItemWithDictionary:(NSDictionary *)dict {
    DiningMealItem *item = [CoreDataManager insertNewObjectForEntityForName:@"DiningMealItem"];
    
    item.station = dict[@"station"];
    item.name = dict[@"name"];
    item.subtitle = dict[@"description"];
    
    for (NSString *name in dict[@"dietary_flags"]) {
        [item addDietaryFlagsObject:[DiningDietaryFlag flagWithName:name]];
    }
    
    return item;
}

@end
