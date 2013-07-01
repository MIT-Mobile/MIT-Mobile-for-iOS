#import "DiningDietaryFlag.h"
#import "DiningMealItem.h"
#import "CoreDataManager.h"

@implementation DiningDietaryFlag

@dynamic name;
@dynamic items;

+ (NSArray *)flagNames {
    return @[
             @"farm to fork",
             @"for your well-being",
             @"halal",
             @"humane",
             @"in balance",
             @"kosher",
             @"made without gluten",
             @"organic",
             @"seafood watch",
             @"vegan",
             @"vegetarian"
             ];
}

+ (void) createDietaryFlagsInStore
{
    [[self flagNames] enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        [self flagWithName:name];
    }];
}

+ (DiningDietaryFlag *)flagWithName:(NSString *)name {
    DiningDietaryFlag *flag = [CoreDataManager getObjectForEntity:@"DiningDietaryFlag" attribute:@"name" value:name];
    if (!flag) {
        flag = [CoreDataManager insertNewObjectForEntityForName:@"DiningDietaryFlag"];
        flag.name = name;
    }
    return flag;
}

+ (NSSet *)flagsWithNames:(NSArray *)flagNames
{
    NSArray *results = [CoreDataManager objectsForEntity:@"DiningDietaryFlag" matchingPredicate:[NSPredicate predicateWithFormat:@"name in %@", flagNames]];
    return [NSSet setWithArray:results];
}

+ (NSDictionary *)detailsForName:(NSString *)name {
    NSDictionary *flagDetails = @{
            @"farm to fork": @{ 
                @"displayName": @"Farm to Fork",
                @"pdfName": @"farm_to_fork"
            },
            @"organic": @{ 
                @"displayName": @"Organic",
                @"pdfName": @"organic"
            },
            @"seafood watch": @{ 
                @"displayName": @"Seafood Watch",
                @"pdfName": @"seafood_watch"
            },
            @"vegan": @{ 
                @"displayName": @"Vegan",
                @"pdfName": @"vegan"
            },
            @"vegetarian": @{ 
                @"displayName": @"Vegetarian",
                @"pdfName": @"vegetarian"
            },
            @"for your well-being": @{ 
                @"displayName": @"For Your Well-Being",
                @"pdfName": @"well_being"
            },
            @"made without gluten": @{ 
                @"displayName": @"Made Without Gluten",
                @"pdfName": @"gluten_free"
            },
            @"halal": @{ 
                @"displayName": @"Halal",
                @"pdfName": @"halal"
            },
            @"kosher": @{ 
                @"displayName": @"Kosher",
                @"pdfName": @"kosher"
            },
            @"humane": @{ 
                @"displayName": @"Humane",
                @"pdfName": @"humane"
            },
            @"in balance": @{ 
                @"displayName": @"In Balance",
                @"pdfName": @"in_balance"
            }
        };
    
    return flagDetails[name];
}

- (NSString *)displayName {
    NSString *displayName = [DiningDietaryFlag detailsForName:self.name][@"displayName"];
    if (!displayName) {
        displayName = self.name;
    }
    return displayName;
}

- (NSString *)pdfPath {
    NSString *pdfName = [DiningDietaryFlag detailsForName:self.name][@"pdfName"];
    return [NSString stringWithFormat:@"dining/%@.pdf", pdfName];
}

- (NSString *)description {
    return self.name;
}

@end
