#import "MITMapCategory.h"

static NSString* const MITMapPlaceIdentifierKey = @"categoryId";
static NSString* const MITMapPlaceNameKey = @"categoryName";
static NSString* const MITMapPlaceSubcategoriesKey = @"subcategories";

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
        self.identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceIdentifierKey];
        self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceNameKey];
        self.subcategories = [aDecoder decodeObjectOfClass:[NSOrderedSet class] forKey:MITMapPlaceSubcategoriesKey];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)placeDictionary
{
    self = [self init];
    if (self) {
        self.name = placeDictionary[MITMapPlaceNameKey];
        self.identifier = placeDictionary[MITMapPlaceIdentifierKey];
        
        if (placeDictionary[MITMapPlaceSubcategoriesKey]) {
            NSMutableOrderedSet *subcategories = [[NSMutableOrderedSet alloc] init];
            for (NSDictionary *placeData in placeDictionary[MITMapPlaceSubcategoriesKey]) {
                MITMapCategory *place = [[MITMapCategory alloc] initWithDictionary:placeData];
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
    [aCoder encodeObject:self.name forKey:MITMapPlaceNameKey];
    [aCoder encodeObject:self.identifier forKey:MITMapPlaceIdentifierKey];
    [aCoder encodeObject:self.subcategories forKey:MITMapPlaceSubcategoriesKey];
}

- (BOOL)hasSubcategories
{
    return (self.subcategories && [self.subcategories count]);
}

@end
