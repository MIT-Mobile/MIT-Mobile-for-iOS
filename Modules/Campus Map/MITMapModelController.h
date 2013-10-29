#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString* const MITMapSearchEntityName;
FOUNDATION_EXTERN NSString* const MITMapPlaceEntityName;
FOUNDATION_EXTERN NSString* const MITMapBookmarkEntityName;

@class MITMapCategory;
@class MITMapPlace;

typedef void (^MITMapResult)(NSOrderedSet *objects, NSError *error);

/** The callback handler for any requests which can be fulfilled by
 *  CoreData.
 *
 *  @param objects A sorted set of the fetched objects. These are guaranteed to be in the main queue context. This will be nil if an error occurs.
 *  @param fetchRequest The fetch request used to retreive the returned objects.  This will be nil if an error occurs.
 *  @param lastUpdated The date of the last successfully refresh of the cached data.
 *  @param error An error.
 */
typedef void (^MITMapFetchedResult)(NSOrderedSet *objects, NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error);

@interface MITMapModelController : NSObject
@property NSTimeInterval searchExpiryInterval;
@property NSTimeInterval placeExpiryInterval;

+ (MITMapModelController*)sharedController;

- (void)categories:(MITMapResult)block;

- (void)recentSearches:(MITMapFetchedResult)block;
- (void)recentSearchesForPartialString:(NSString*)string loaded:(MITMapFetchedResult)block;

- (void)searchMapWithQuery:(NSString*)queryText loaded:(MITMapFetchedResult)block;
- (void)places:(MITMapFetchedResult)block;
- (void)placesInCategory:(MITMapCategory*)categoryId loaded:(MITMapFetchedResult)block;

- (NSUInteger)numberOfBookmarks;
- (void)bookmarkedPlaces:(MITMapFetchedResult)block;
- (void)addBookmarkForPlace:(MITMapPlace*)place;
- (void)removeBookmarkForPlace:(MITMapPlace*)place;
- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index;
@end
