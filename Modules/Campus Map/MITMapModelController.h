#import <Foundation/Foundation.h>
#import "MITMapModel.h"
#import "MITMobileResources.h"

@class MITMapCategory;
@class MITMapPlace;
@class MITMobileResource;

@interface MITMapModelController : NSObject
@property NSTimeInterval searchExpiryInterval;

+ (MITMapModelController*)sharedController;

- (NSFetchRequest*)categories:(MITMobileManagedResult)block;

- (NSManagedObjectID*)addRecentSearch:(NSString*)queryString;
- (NSFetchRequest*)recentSearches:(MITMobileManagedResult)block;
- (NSFetchRequest*)recentSearchesForPartialString:(NSString*)string loaded:(MITMobileManagedResult)block;

- (void)searchMapWithQuery:(NSString*)queryText loaded:(MITMobileResult)block;
- (NSFetchRequest*)places:(MITMobileManagedResult)block;
- (void)placesInCategory:(MITMapCategory*)categoryId loaded:(MITMobileManagedResult)block;

- (NSUInteger)numberOfBookmarks;
- (NSFetchRequest*)bookmarkedPlaces:(MITMobileManagedResult)block;

- (void)bookmarkPlaces:(NSArray*)places completion:(void (^)(NSError* error))block;
- (void)removeBookmarkForPlace:(MITMapPlace*)place completion:(void (^)(NSError* error))block;
- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index completion:(void (^)(NSError* error))block;
@end
