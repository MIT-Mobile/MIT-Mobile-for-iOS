#import "MapBookmarkManager.h"
#import "MITMapPlace.h"

@interface MapBookmarkManager ()
@property (nonatomic,copy) NSMutableOrderedSet *bookmarkSet;

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
        NSArray *existingBookmarks = [NSArray arrayWithContentsOfURL:[self bookmarksURL]];
        _bookmarkSet = [[NSMutableOrderedSet alloc] initWithArray:existingBookmarks];

	}
	
	return self;
}

- (NSArray*)bookmarks
{
    return [self.bookmarkSet array];
}

#pragma mark Private category
- (NSURL*)bookmarksURL
{
    NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:NO
                                                           error:nil];

    return [NSURL URLWithString:@"mapBookmarks-new.plist"
                  relativeToURL:url];
}

#pragma mark Bookmark Management
- (void)addBookmark:(MITMapPlace*)place
{
    [self.bookmarkSet addObject:place];
}

- (void)removeBookmark:(MITMapPlace*)place
{
    [self.bookmarkSet removeObject:place];
}

- (BOOL)isBookmarked:(MITMapPlace*)place
{
    return [self.bookmarkSet containsObject:place];
}

- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to
{
    [self.bookmarkSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:from] toIndex:to];
}

@end
