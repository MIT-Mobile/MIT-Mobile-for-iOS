#import <Foundation/Foundation.h>


@interface MapBookmarkManager : NSObject
@property (nonatomic,copy,readonly) NSArray* bookmarks;
+ (MapBookmarkManager*)defaultManager;

- (void)addBookmark:(NSString*)bookmarkID title:(NSString*)title subtitle:(NSString*)subtitle data:(NSDictionary*)data;
- (void)removeBookmark:(NSString*)bookmarkID;
- (BOOL)isBookmarked:(NSString*)bookmarkID;
- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to;

@end
