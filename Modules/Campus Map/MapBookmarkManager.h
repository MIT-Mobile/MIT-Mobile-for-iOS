#import <Foundation/Foundation.h>

@class MITMapPlace;

@interface MapBookmarkManager : NSObject
@property (nonatomic,copy,readonly) NSArray* bookmarks;
+ (MapBookmarkManager*)defaultManager;

- (void)addBookmark:(MITMapPlace*)place;
- (void)removeBookmark:(MITMapPlace*)place;
- (BOOL)isBookmarked:(MITMapPlace*)place;
- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to;

@end
