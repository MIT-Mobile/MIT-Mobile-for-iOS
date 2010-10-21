#import "NewsStory.h"
#import "CoreDataManager.h"

@interface NewsStory (PrimitiveAccessors)

- (NSString *)primitiveThumbnailURL;
- (void)setPrimitiveThumbnailURL:(NSString *)newURL;

- (NSMutableSet*)primitiveCategories;
- (void)setPrimitiveCategories:(NSMutableSet*)value;

@end


@implementation NewsStory

@dynamic author;
@dynamic body;
@dynamic categories;
@dynamic topStory;
@dynamic searchResult;
@dynamic bookmarked;
@dynamic summary;
@dynamic featured;
@dynamic link;
@dynamic postDate;
@dynamic story_id;
@dynamic title;
@dynamic read;
@dynamic inlineImage;
@dynamic galleryImages;
@dynamic allImages;

// stories can be listed in multiple categories
- (void)addCategory:(NSInteger)newCategory {
    // reuse existing category objects
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id == %d", newCategory];
    NSManagedObject *value = [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate] lastObject];
    if (!value) {
        value = [CoreDataManager insertNewObjectForEntityForName:NewsCategoryEntityName];
        [value setValue:[NSNumber numberWithInteger:newCategory] forKey:@"category_id"];
    }
    
    NSMutableSet *categoriesSet = [self mutableSetValueForKey:@"categories"];

    [categoriesSet addObject:value];
}

- (void)addGalleryImage:(NewsImage *)newImage {
    if (newImage) {
        NSMutableSet *gallerySet = [self mutableSetValueForKey:@"galleryImages"];
        [gallerySet addObject:newImage];
    }
}

- (NSArray *)allImages {
    NSMutableArray *result = [NSMutableArray array];
    if (self.inlineImage) {
        [result addObject:self.inlineImage];
    }
    NSSortDescriptor *ordinalitySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:NO];
    NSArray *mediaImages = [[self.galleryImages allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:ordinalitySortDescriptor]];
    [ordinalitySortDescriptor release];
    [result addObjectsFromArray:mediaImages];
    if ([result count] == 0) {
        result = nil;
    }
    return result;
}

@end
