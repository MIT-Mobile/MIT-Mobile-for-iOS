#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NewsStory;

@interface NewsCategory : NSManagedObject

@property (nonatomic, strong) NSNumber * expectedCount;
@property (nonatomic, strong) NSNumber * category_id;
@property (nonatomic, strong) NSDate * lastUpdated;
@property (nonatomic, copy) NSSet *stories;
@end

@interface NewsCategory (CoreDataGeneratedAccessors)

- (void)addStoriesObject:(NewsStory *)value;
- (void)removeStoriesObject:(NewsStory *)value;
- (void)addStories:(NSSet *)values;
- (void)removeStories:(NSSet *)values;

@end
