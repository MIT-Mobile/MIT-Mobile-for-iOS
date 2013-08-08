#import "MapBookmarkManager.h"

@interface MapBookmarkManager ()
@property (nonatomic,copy) NSArray *bookmarks;

- (NSURL*)bookmarksURL;
@end


@implementation MapBookmarkManager
#pragma mark Creation and initialization
+ (MapBookmarkManager*)defaultManager
{
    static MapBookmarkManager* defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[MapBookmarkManager alloc] init];
    });

    return defaultManager;
}


- (id)init
{
	self = [super init];
	if (self) {
		// see if we can load the bookmarks from disk.
        _bookmarks = [[NSArray alloc] initWithContentsOfURL:[self bookmarksURL]];
	}
	
	return self;
}

#pragma mark Private category
- (NSURL*)bookmarksURL
{
    NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:NO
                                                           error:nil];

    return [NSURL URLWithString:@"mapBookmarks.plist"
                  relativeToURL:url];
}

- (void)setBookmarks:(NSArray *)bookmarks
{
    if (![_bookmarks isEqualToArray:bookmarks]) {
        _bookmarks = [bookmarks copy];

        [_bookmarks writeToURL:[self bookmarksURL]
                    atomically:YES];
    }
}

#pragma mark Bookmark Management
- (void)addBookmark:(NSString*)bookmarkID title:(NSString*)title subtitle:(NSString*)subtitle data:(NSDictionary*) data
{
	NSMutableDictionary* dictionary = [@{@"id" : bookmarkID,
                                         @"title" : title} mutableCopy];

	if (subtitle) {
		dictionary[@"subtitle"] = subtitle;
    }
	
	if (data) {
		dictionary[@"data"] = data;
	}

    NSMutableArray *newBookmarks = [[NSMutableArray alloc] initWithArray:self.bookmarks];
	[newBookmarks addObject:dictionary];
    self.bookmarks = newBookmarks;
}

- (void)removeBookmark:(NSString*)bookmarkID
{
    NSMutableArray *newBookmarks = [self.bookmarks mutableCopy];
    [newBookmarks enumerateObjectsUsingBlock:^(NSDictionary *bookmark, NSUInteger idx, BOOL *stop) {
        if ([bookmark[@"id"] isEqualToString:bookmarkID]) {
            [newBookmarks removeObjectAtIndex:idx];
            (*stop) = YES;
        }
    }];

    self.bookmarks = newBookmarks;
}

- (BOOL)isBookmarked:(NSString*)bookmarkID
{
    NSArray *matchingBookmarks = [self.bookmarks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id = %@", bookmarkID]];
    return ([matchingBookmarks count] > 0);
}

- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to
{
    if (to != from) {
        NSMutableArray *newBookmarks = [self.bookmarks mutableCopy];
        NSDictionary *bookmark = newBookmarks[from];
        [newBookmarks removeObjectAtIndex:from];

        // Decrement the 'to' since we just removed the 'from'
        // bookmark.
        to = MIN(--to,[newBookmarks count]);
        newBookmarks[to] = bookmark;
    }
}

@end
