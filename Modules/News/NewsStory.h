#import <CoreData/CoreData.h>
#import "NewsImage.h"

@interface NewsStory : NSManagedObject

- (void)addCategory:(NSInteger)newCategory;
- (void)addGalleryImage:(NewsImage *)newImage;

@property (nonatomic, strong) NSNumber *story_id;
@property (nonatomic, strong) NSDate *postDate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *link;

@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *body;

@property (nonatomic, copy) NSNumber *featured;

@property (nonatomic, copy) NSSet *categories;
@property (nonatomic, strong) NSNumber *topStory;
@property (nonatomic, strong) NSNumber *searchResult;
@property (nonatomic, strong) NSNumber *bookmarked;

@property (nonatomic, strong) NewsImage *inlineImage;
@property (nonatomic, copy) NSSet *galleryImages;
@property (nonatomic, readonly) NSArray *allImages;

@property (nonatomic, strong) NSNumber *read;

@end
