#import <Foundation/Foundation.h>

@class MITNewsStory;
@class MITNewsCategory;
@class MITResultsPager;
@class MITNewsRecentSearchQuery;

@interface MITNewsModelController : NSObject
+ (instancetype)sharedController;

- (void)categories:(void (^)(NSArray *categories, NSError *error))block;
- (void)featuredStoriesWithOffset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, NSDictionary* pagingMetadata, NSError *error))completion;
- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, NSDictionary* pagingMetadata, NSError *error))block;

- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString;
- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError *)addError;
- (void)clearRecentSearchesWithError:(NSError *)addError;

@end
