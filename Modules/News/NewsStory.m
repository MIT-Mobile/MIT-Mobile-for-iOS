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
        [value setValue:@(newCategory) forKey:@"category_id"];
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
    NSMutableArray *mediaImages = [NSMutableArray arrayWithObject:self.inlineImage];
    [mediaImages addObjectsFromArray:[self.galleryImages allObjects]];
    
    [mediaImages sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:NO]]];
    return mediaImages;
}

@end
