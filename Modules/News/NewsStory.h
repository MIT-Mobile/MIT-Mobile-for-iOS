#import <CoreData/CoreData.h>
#import "NewsImage.h"

@interface NewsStory : NSManagedObject

- (void)addCategory:(NSInteger)newCategory;
- (void)addGalleryImage:(NewsImage *)newImage;

@property (nonatomic, retain) NSNumber *story_id;
@property (nonatomic, retain) NSDate *postDate;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *link;

@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *body;

@property (nonatomic, retain) NSNumber *featured;

@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSNumber *topStory;
@property (nonatomic, retain) NSNumber *searchResult;
@property (nonatomic, retain) NSNumber *bookmarked;

@property (nonatomic, retain) NewsImage *inlineImage;
@property (nonatomic, retain) NSSet *galleryImages;
@property (nonatomic, readonly) NSArray *allImages;

@property (nonatomic, retain) NSNumber *read;

@end
