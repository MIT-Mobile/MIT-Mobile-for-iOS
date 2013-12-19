#import <Foundation/Foundation.h>
#import "MITMobile.h"

FOUNDATION_EXTERN NSString* const MITMapSearchEntityName;
FOUNDATION_EXTERN NSString* const MITMapCategoryEntityName;
FOUNDATION_EXTERN NSString* const MITMapPlaceEntityName;
FOUNDATION_EXTERN NSString* const MITMapPlaceContentEntityName;
FOUNDATION_EXTERN NSString* const MITMapBookmarkEntityName;

FOUNDATION_EXTERN NSString* const MITCoreDataErrorDomain;

typedef NS_ENUM(NSUInteger, MITCoreDataErrorCode) {
    MITCoreDataMethodNotImplementedError = 0
};

@class MITMapCategory;
@class MITMapPlace;
@class MITMobileResource;

@interface MITMapModelController : NSObject
@property NSTimeInterval searchExpiryInterval;

+ (MITMapModelController*)sharedController;

- (NSFetchRequest*)categories:(MITMobileManagedResult)block;

- (NSFetchRequest*)recentSearches:(MITMobileManagedResult)block;
- (NSFetchRequest*)recentSearchesForPartialString:(NSString*)string loaded:(MITMobileManagedResult)block;

- (void)searchMapWithQuery:(NSString*)queryText loaded:(MITMobileManagedResult)block;
- (NSFetchRequest*)places:(MITMobileManagedResult)block;
- (void)placesInCategory:(MITMapCategory*)categoryId loaded:(MITMobileManagedResult)block;

- (NSUInteger)numberOfBookmarks;
- (NSFetchRequest*)bookmarkedPlaces:(MITMobileManagedResult)block;

- (void)bookmarkPlaces:(NSArray*)places completion:(void (^)(NSError* error))block;
- (void)removeBookmarkForPlace:(MITMapPlace*)place completion:(void (^)(NSError* error))block;
- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index completion:(void (^)(NSError* error))block;
@end
