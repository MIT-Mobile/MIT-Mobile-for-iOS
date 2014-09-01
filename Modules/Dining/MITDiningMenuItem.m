#import "MITDiningMenuItem.h"
#import "MITDiningMeal.h"
#import "UIImage+PDF.h"

@implementation MITDiningMenuItem

@dynamic dietaryFlags;
@dynamic itemDescription;
@dynamic name;
@dynamic station;
@dynamic meal;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"station", @"name"]];
    [mapping addAttributeMappingsFromDictionary:@{@"description" : @"itemDescription",
                                                  @"dietary_flags" : @"dietaryFlags"}];
    
    
    return mapping;
}

+ (NSString *)pdfNameForDietaryFlag:(NSString *)flag
{
    NSDictionary *flagPdfs = @{
        @"farm to fork": @"dining/farm_to_fork.pdf",
        @"organic": @"dining/organic.pdf",
        @"seafood watch": @"dining/seafood_watch.pdf",
        @"vegan": @"dining/vegan.pdf",
        @"vegetarian": @"dining/vegetarian.pdf",
        @"for your well-being": @"dining/well_being.pdf",
        @"made without gluten": @"dining/gluten_free.pdf",
        @"halal": @"dining/halal.pdf",
        @"kosher": @"dining/kosher.pdf",
        @"humane": @"dining/humane.pdf",
        @"in balance": @"dining/in_balance.pdf"
    };
    
    return flagPdfs[flag];
}

+ (NSString *)displayNameForDietaryFlag:(NSString *)flag
{
    NSDictionary *flagDisplayNames = @{
        @"farm to fork": @"Farm to Fork",
        @"organic": @"Organic",
        @"seafood watch": @"Seafood Watch",
        @"vegan": @"Vegan",
        @"vegetarian": @"Vegetarian",
        @"for your well-being": @"For Your Well-Being",
        @"made without gluten": @"Made Without Gluten",
        @"halal": @"Halal",
        @"kosher": @"Kosher",
        @"humane": @"Humane",
        @"in balance": @"In Balance"
    };
    
    return flagDisplayNames[flag];
}

- (NSAttributedString *)attributedNameWithDietaryFlags
{
    NSMutableAttributedString *itemName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", self.name]];
    
    for (NSString *dietaryFlag in self.dietaryFlags) {
        UIImage *dietaryFlagImage = [UIImage imageWithPDFNamed:[MITDiningMenuItem pdfNameForDietaryFlag:dietaryFlag] atSize:CGSizeMake(14, 14)];
        NSTextAttachment *dietaryFlagAttachment = [[NSTextAttachment alloc] init];
        dietaryFlagAttachment.image = dietaryFlagImage;
        
        NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:dietaryFlagAttachment];
        [itemName appendAttributedString:imageString];
    }
    
    return itemName;
}


@end
