#import <Foundation/Foundation.h>

@class MITNewsStory;
@class MITNewsCategory;
@class MITResultsPager;

@interface MITNewsModelController : NSObject
+ (instancetype)sharedController;

- (void)categories:(void (^)(NSArray *categories, NSError *error))block;
- (void)featuredStoriesWithOffset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, MITResultsPager* pager, NSError *error))completion;
- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, MITResultsPager* pager, NSError *error))block;

@end
