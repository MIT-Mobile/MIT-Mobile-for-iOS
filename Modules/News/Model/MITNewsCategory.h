#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITNewsStory;

@interface MITNewsCategory : NSManagedObject

@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, strong) NSDate * lastUpdated;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSSet *stories;

+ (NSString*)entityName;
@end

@interface MITNewsCategory (CoreDataGeneratedAccessors)

- (void)addStoriesObject:(MITNewsStory *)value;
- (void)removeStoriesObject:(MITNewsStory *)value;
- (void)addStories:(NSSet *)values;
- (void)removeStories:(NSSet *)values;

@end
