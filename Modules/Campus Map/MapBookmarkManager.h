#import <Foundation/Foundation.h>

@class MITMapPlace;

// This class is *not* thread-safe under mutation.
// If this class is called from any thread other
// than the main thread, the behavior will be undetermined.
// TODO: Move to MITMapModelController and switch over to CoreData
DEPRECATED_ATTRIBUTE
@interface MapBookmarkManager : NSObject
@property (nonatomic,copy,readonly) NSArray* bookmarks;
+ (MapBookmarkManager*)defaultManager;

- (void)addBookmark:(MITMapPlace*)place;
- (void)removeBookmark:(MITMapPlace*)place;
- (BOOL)isBookmarked:(MITMapPlace*)place;
- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to;

@end
