#import <Foundation/Foundation.h>

/** The callback handler for any data requests.
 *
 *  @param objects A sorted set of the fetched objects
 *  @param lastUpdated The date of the last API update.
 *  @param finished YES if the block will not called again.
 *  @param error An error.
 */
typedef void (^MITMapResponse)(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error);

@interface MITMapModelController : NSObject
+ (MITMapModelController*)sharedController;

- (void)searchMapWithQuery:(NSString*)queryText loaded:(MITMapResponse)block;
- (void)placeCategories:(MITMapResponse)block;
- (void)places:(MITMapResponse)block;
- (void)placesInCategory:(NSString*)categoryId loaded:(MITMapResponse)block;

@end
