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

        [self migrateBookmarks];
	}
	
	return self;
}

- (void)migrateBookmarks
{
    NSURL *userDocumentsURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                     inDomain:NSUserDomainMask
                                                            appropriateForURL:nil
                                                                       create:NO
                                                                        error:nil];

    NSURL *bookmarksURL = [NSURL URLWithString:@"mapBookmarks.plist"
                                   relativeToURL:userDocumentsURL];
    NSArray *bookmarksV1 = [NSArray arrayWithContentsOfURL:bookmarksURL];
    if (bookmarksV1) {
        // Migrate the bookmarks from the original version of the app
        // The format of the saved bookmarks changed in the 3.5 release
        for (NSDictionary *savedBookmark in bookmarksV1) {
            MITMapPlace *place = [[MITMapPlace alloc] initWithDictionary:savedBookmark[@"data"]];
            if (place) {
                [self.bookmarkSet addObject:place];
            }
        }

        //[[NSFileManager defaultManager] removeItemAtURL:bookmarksURL
        //                                          error:nil];
    }
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

    return [NSURL URLWithString:@"mapBookmarks-v2.plist"
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
