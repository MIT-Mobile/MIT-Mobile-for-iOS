#import "DiningMealItem.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

@implementation DiningMealItem

@dynamic name;
@dynamic subtitle;
@dynamic station;
@dynamic meal;
@dynamic dietaryFlags;
@dynamic ordinality;

+ (DiningMealItem *)newItemWithDictionary:(NSDictionary *)dict possibleFlags:(NSArray *)possibleFlags {
    DiningMealItem *item = [CoreDataManager insertNewObjectForEntityForName:@"DiningMealItem"];
    
    item.station = dict[@"station"];
    item.name = dict[@"name"];
    item.subtitle = dict[@"description"];
    
    NSArray *flagNames = dict[@"dietary_flags"];
    NSMutableSet *flags = [[NSMutableSet alloc] init];
    [possibleFlags enumerateObjectsUsingBlock:^(DiningDietaryFlag *flag, NSUInteger idx, BOOL *stop) {
        if ([flagNames containsObject:flag.name]) {
            [flags addObject:flag];
        }
    }];
    if ([flags count] > 0) {
        [item setDietaryFlags:flags];
    }
    
    return item;
}

@end
