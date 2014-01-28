#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITNewsCategory, MITNewsImage;

@interface MITNewsStory : MITManagedObject

@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * body;
@property (nonatomic, strong) NSNumber * featured;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, strong) NSDate * publishedAt;
@property (nonatomic, strong) NSNumber * read;
@property (nonatomic, strong) NSURL * sourceURL;
@property (nonatomic, copy) NSString * dek;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) NSNumber * topStory;
@property (nonatomic, strong) MITNewsCategory *category;
@property (nonatomic, copy) NSSet *images;
@end

@interface MITNewsStory (CoreDataGeneratedAccessors)

- (void)addImagesObject:(MITNewsImage *)value;
- (void)removeImagesObject:(MITNewsImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
