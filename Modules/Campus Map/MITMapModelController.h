#import <Foundation/Foundation.h>

extern NSString* const MITMapSearchEntityName;

@class MITMapCategory;
@class MITMapPlace;

/** The callback handler for any data requests.
 *
 *  @param objects A sorted set of the fetched objects
 *  @param lastUpdated The date of the last API update.
 *  @param finished YES if the block will not called again.
 *  @param error An error.
 */
typedef void (^MITMapResponse)(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error);

@interface MITMapModelController : NSObject
@property NSTimeInterval searchExpiryInterval;
@property NSTimeInterval placeExpiryInterval;

+ (MITMapModelController*)sharedController;

- (void)recentSearches:(MITMapResponse)block;
- (void)recentSearchesForPartialString:(NSString*)string loaded:(MITMapResponse)block;

- (void)searchMapWithQuery:(NSString*)queryText loaded:(MITMapResponse)block;
- (void)categories:(MITMapResponse)block;
- (void)places:(MITMapResponse)block;
- (void)placesInCategory:(MITMapCategory*)categoryId loaded:(MITMapResponse)block;

- (void)bookmarkedPlaces:(MITMapResponse)block;
- (void)addBookmarkForPlace:(MITMapPlace*)place;
- (void)removeBookmarkForPlace:(MITMapPlace*)place;
- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index;
@end
