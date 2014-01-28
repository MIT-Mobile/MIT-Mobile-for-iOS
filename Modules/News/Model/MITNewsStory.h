#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITNewsCategory, MITNewsImage;

@interface MITNewsStory : MITManagedObject

@property (nonatomic, copy) NSString * body;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, strong) NSNumber * read;
@property (nonatomic, strong) NSNumber * featured;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, strong) NSURL * sourceURL;
@property (nonatomic, strong) NSDate * publishedAt;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) NSNumber * topStory;
@property (nonatomic, copy) NSString * summary;
@property (nonatomic, copy) NSSet *categories;
@property (nonatomic, copy) NSSet *images;

@end

@interface MITNewsStory (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(MITNewsCategory *)value;
- (void)removeCategoriesObject:(MITNewsCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addImagesObject:(MITNewsImage *)value;
- (void)removeImagesObject:(MITNewsImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
