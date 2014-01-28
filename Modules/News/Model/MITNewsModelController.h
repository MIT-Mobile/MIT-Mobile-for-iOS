#import <Foundation/Foundation.h>

@class MITNewsStory;
@class MITNewsCategory;
@class MITMobileResultsPaginator;

@interface MITNewsModelController : NSObject
+ (instancetype)sharedController;

- (void)categories:(void (^)(NSArray *categories, NSError *error))block;
- (MITMobileResultsPaginator*)storiesInCategory:(MITNewsCategory*)category batchSize:(NSUInteger)numberOfStories completion:(void (^)(NSArray *stories, NSError *error))block;

@end
