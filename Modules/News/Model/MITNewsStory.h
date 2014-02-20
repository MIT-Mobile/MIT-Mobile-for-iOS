#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITNewsCategory, MITNewsImage;

@interface MITNewsStory : MITManagedObject <MITMappedObject>

@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * body;
@property (nonatomic, copy) NSString * dek;
@property (nonatomic, strong) NSNumber * featured;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, strong) NSDate * publishedAt;
@property (nonatomic, strong) NSNumber * read;
@property (nonatomic, strong) NSURL * sourceURL;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSNumber * topStory;
@property (nonatomic, copy) NSString * type;

@property (nonatomic, strong) MITNewsCategory *category;
@property (nonatomic, strong) MITNewsImage *coverImage;
@property (nonatomic, copy) NSOrderedSet *galleryImages;
@end

@interface MITNewsStory (CoreDataGeneratedAccessors)

- (void)insertObject:(MITNewsImage *)value inGalleryImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGalleryImagesAtIndex:(NSUInteger)idx;
- (void)insertGalleryImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGalleryImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGalleryImagesAtIndex:(NSUInteger)idx withObject:(MITNewsImage *)value;
- (void)replaceGalleryImagesAtIndexes:(NSIndexSet *)indexes withGalleryImages:(NSArray *)values;
- (void)addGalleryImagesObject:(MITNewsImage *)value;
- (void)removeGalleryImagesObject:(MITNewsImage *)value;
- (void)addGalleryImages:(NSOrderedSet *)values;
- (void)removeGalleryImages:(NSOrderedSet *)values;
@end
