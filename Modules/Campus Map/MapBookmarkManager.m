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
        _bookmarkSet = [[NSMutableOrderedSet alloc] init];

		// Try and load the bookmarks from disk.
        NSData *encodedBookmarks = [[NSData alloc] initWithContentsOfURL:[self bookmarksURL]];
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:encodedBookmarks];
        [_bookmarkSet unionOrderedSet:[decoder decodeObject]];

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
        /*for (NSDictionary *savedBookmark in bookmarksV1) {
            MITMapPlace *place = [[MITMapPlace alloc] initWithDictionary:savedBookmark[@"data"]];
            if (place) {
                [self.bookmarkSet addObject:place];
            }
        }

        [[NSFileManager defaultManager] removeItemAtURL:bookmarksURL
                                                  error:nil];*/
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

- (void)synchronizeWithBackingStore
{
    // This should maintain the same behavior as the older version of the
    // code (for now). When any change is made to the bookmarks (add/remove/reorder)
    // the backing ordered set is flushed to disk. Since performing any changes to
    // the bookmarks is relatively rare and non-performance dependent, take the
    // naive approach for now.
    NSMutableData *encodedData = [[NSMutableData alloc] init];
    NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:encodedData];
    [coder encodeRootObject:self.bookmarkSet];
    [coder finishEncoding];

    NSError *error = nil;
    [encodedData writeToURL:[self bookmarksURL]
                    options:NSDataWritingAtomic
                      error:&error];

    if (error) {
        DDLogWarn(@"Failed to flush saved bookmarks to store: %@", error);
    }
}

#pragma mark Bookmark Management
- (void)addBookmark:(MITMapPlace*)place
{
    [self.bookmarkSet addObject:place];
    [self synchronizeWithBackingStore];
}

- (void)removeBookmark:(MITMapPlace*)place
{
    [self.bookmarkSet removeObject:place];
    [self synchronizeWithBackingStore];
}

- (BOOL)isBookmarked:(MITMapPlace*)place
{
    return [self.bookmarkSet containsObject:place];
}

- (void)moveBookmarkFromRow:(NSInteger)from toRow:(NSInteger)to
{
    [self.bookmarkSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:from] toIndex:to];
    [self synchronizeWithBackingStore];
}

@end
