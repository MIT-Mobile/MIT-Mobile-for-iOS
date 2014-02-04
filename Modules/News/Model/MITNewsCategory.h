#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITNewsStory;

@interface MITNewsCategory : MITManagedObject

@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) NSNumber * order;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSSet *stories;
@end

@interface MITNewsCategory (CoreDataGeneratedAccessors)

- (void)addStoriesObject:(MITNewsStory *)value;
- (void)removeStoriesObject:(MITNewsStory *)value;
- (void)addStories:(NSSet *)values;
- (void)removeStories:(NSSet *)values;

@end
