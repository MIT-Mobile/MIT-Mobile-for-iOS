#import "MITMapCategory.h"

static NSString* const MITMapCategoryIdentifierKey = @"categoryId";
static NSString* const MITMapCategoryNameKey = @"categoryName";
static NSString* const MITMapCategorySubcategoriesKey = @"subcategories";

@interface MITMapCategory ()
@property (copy) NSString *name;
@property (copy) NSString *identifier;
@property (copy) NSOrderedSet *subcategories;
@property (copy) MITMapCategory *parent;
@end

@implementation MITMapCategory
+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        self.identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapCategoryIdentifierKey];
        self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapCategoryNameKey];
        self.subcategories = [aDecoder decodeObjectOfClass:[NSOrderedSet class] forKey:MITMapCategorySubcategoriesKey];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)placeDictionary
{
    self = [self init];
    if (self) {
        self.name = placeDictionary[MITMapCategoryNameKey];
        self.identifier = placeDictionary[MITMapCategoryIdentifierKey];
        
        if (placeDictionary[MITMapCategorySubcategoriesKey]) {
            NSMutableOrderedSet *subcategories = [[NSMutableOrderedSet alloc] init];
            for (NSDictionary *placeData in placeDictionary[MITMapCategorySubcategoriesKey]) {
                MITMapCategory *place = [[MITMapCategory alloc] initWithDictionary:placeData];
                place.parent = self;
                [subcategories addObject:place];
            }
            
            self.subcategories = subcategories;
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MITMapCategory *category = [[MITMapCategory allocWithZone:zone] init];
    category.name = self.name;
    category.identifier = self.identifier;
    category.subcategories = self.subcategories;
    
    return category;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:MITMapCategoryNameKey];
    [aCoder encodeObject:self.identifier forKey:MITMapCategoryIdentifierKey];
    [aCoder encodeObject:self.subcategories forKey:MITMapCategorySubcategoriesKey];
}

- (BOOL)hasSubcategories
{
    return (self.subcategories && [self.subcategories count]);
}

- (NSArray*)pathComponents
{
    NSMutableArray *components = [[NSMutableArray alloc] init];
    MITMapCategory *category = self;

    while (category) {
        [components insertObject:category.name
                         atIndex:0];
        category = category.parent;
    }

    return components;
}

@end
