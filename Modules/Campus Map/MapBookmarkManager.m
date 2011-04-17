#import "MapBookmarkManager.h"


@interface MapBookmarkManager (Private)

-(NSString*) getBookmarkFilename;

-(void) save;

@end



static MapBookmarkManager* s_mapBookmarksManager = nil;

@implementation MapBookmarkManager
@synthesize bookmarks = _bookmarks;

#pragma mark Creation and initialization
+(MapBookmarkManager*) defaultManager
{
	if(nil == s_mapBookmarksManager)
	{
		s_mapBookmarksManager = [[MapBookmarkManager alloc] init];
	}
	
	return s_mapBookmarksManager;
}


-(id) init
{
	self = [super init];
	if (self) {
		NSString* filename = [self getBookmarkFilename];
		
		// see if we can load the bookmarks from disk. 
		_bookmarks = [[NSMutableArray arrayWithContentsOfFile:filename] retain];
		
		// if there was no file on disk, create the array from scratch
		if (nil == _bookmarks) {
			_bookmarks = [[NSMutableArray alloc] init];
		}
	}
	
	return self;
}

-(void) dealloc
{
	[_bookmarks release];
	
	[super dealloc];
}

#pragma mark Private category
-(NSString*) getBookmarkFilename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:@"mapBookmarks.plist"];
}

-(void) save
{
	NSString* filename = [self getBookmarkFilename];
	[_bookmarks writeToFile:filename atomically:YES];
}


#pragma mark Bookmark Management
-(void) addBookmark:(NSString*) bookmarkID title:(NSString*)title subtitle:(NSString*)subtitle data:(NSDictionary*) data
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:bookmarkID, @"id", title, @"title", nil, nil];

	if (nil != subtitle) {
		[dictionary setObject:subtitle forKey:@"subtitle"];
	}
	
	if(nil != data)
	{
		[dictionary setObject:data forKey:@"data"];
	}
	
	[_bookmarks addObject:dictionary];
	[self save];
}

-(void) removeBookmark:(NSString*) bookmarkID
{
	NSString* idfield = @"id";
	
	for(int idx = _bookmarks.count - 1; idx >= 0; idx--)
	{
		NSDictionary* dictionary = [_bookmarks objectAtIndex:idx];
		NSString* uniqueID = [dictionary objectForKey:idfield];
		if([uniqueID isEqualToString:bookmarkID])
		{
			[_bookmarks removeObjectAtIndex:idx];
			[self save];
			break;
		}
	}
}

-(BOOL) isBookmarked:(NSString*) bookmarkID
{
	NSString* idfield = @"id";
	
	for (NSDictionary* dictionary in _bookmarks) 
	{
		NSString* uniqueID = [dictionary objectForKey:idfield];
		if([uniqueID isEqualToString:bookmarkID])
		{
			return YES;
		}
	}
	
	return NO;
}

-(void) moveBookmarkFromRow:(int) from toRow:(int)to
{
    if (to != from) 
	{
        
		id obj = [_bookmarks objectAtIndex:from];
        [obj retain];

        [_bookmarks removeObjectAtIndex:from];
        
		if (to >= [_bookmarks count]) 
		{
            [_bookmarks addObject:obj];
        }
		else 
		{
            [_bookmarks insertObject:obj atIndex:to];
        }
        [obj release];
    }
	
	[self save];
}

@end
