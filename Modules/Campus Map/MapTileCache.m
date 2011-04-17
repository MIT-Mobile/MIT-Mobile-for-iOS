
#import "MapTileCache.h"
//#import "PostData.h"
#import "SaveOperation.h"
#import "MIT_MobileAppDelegate.h"
#import "MapLevel.h"

#define kInMemoryTileLimit 4
#define kTileSize 256
#define LogRect(rect, message) DLog(@"%@ rect: %f %f %f %f", message,  rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)

#define kLastUpdatedKey @"last_updated"


NSString * const MapCacheReset           = @"MapCacheReset";

static MapTileCache* s_cache;

@implementation MapTileCache
@synthesize serviceURL = _serviceURL;
//@synthesize delegate = _delegate;
@synthesize mapLevels = _mapLevels;




+(MapTileCache*) cache
{
	if(s_cache == nil)
	{
		s_cache = [[MapTileCache alloc] init];
	}
	
	return s_cache;
}

-(id) init
{
	self = [super init];
	if (self) {
		_saveOperationQueue = [[NSOperationQueue alloc] init];
		
		
		NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:[self mapTimestampFilename]];
		_mapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
		
		MITMobileWebAPI* api = [MITMobileWebAPI jsonLoadedDelegate:self];
		[api requestObject:[NSDictionary dictionaryWithObject:@"tilesupdated" forKey:@"command"] pathExtension:@"map"];
		
		//_recentTilesIndex = [[NSMutableArray alloc] initWithCapacity:kInMemoryTileLimit + 1];
		//_recentTiles = [[NSMutableDictionary alloc] initWithCapacity:kInMemoryTileLimit + 1];
	}
	
	NSString* path = [[NSBundle mainBundle] pathForResource:@"MapLevels" ofType:@"plist" inDirectory:@"map"];
	NSDictionary* mapInfo = [NSDictionary dictionaryWithContentsOfFile:path];
	
	NSArray* levels = [mapInfo objectForKey:@"MapLevels"];
	
	NSMutableArray* mapLevels = [NSMutableArray arrayWithCapacity:levels.count];
	for (NSDictionary* levelInfo in levels) {
		MapLevel* level = [MapLevel levelWithInfo:levelInfo];
		[mapLevels addObject:level];
	}
	
	self.mapLevels = mapLevels;
	
	// load the default tiles.
	/*
	[self getTileForLevel:15 row:12120 col:9913];
	[self getTileForLevel:15 row:12120 col:9912];
	[self getTileForLevel:15 row:12119 col:9913];
	[self getTileForLevel:15 row:12119 col:9913];
	*/
	
	return self;
}

-(NSString*) pathForTileAtLevel:(int)level row:(int)row col:(int)col
{
	NSString* tileCachePath = [MapTileCache tileCachePath];
	return [tileCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%d/%d", level, row, col]];
}

+(NSString*) tileCachePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* cachePath = [paths objectAtIndex:0];
	return [cachePath stringByAppendingPathComponent:@"tile"];
}

-(UIImage*) getTileForLevel:(int)level row:(int)row col:(int)col
{
	return [self getTileForLevel:level row:row col:col onlyFromCache:NO];
}

-(UIImage*) getTileForLevel:(int)level row:(int)row col:(int)col onlyFromCache:(BOOL)onlyFromCache;
{
	UIImage* image = nil;
	
	// see if it is in our cache
	/*
	NSString* cacheIndex = [NSString stringWithFormat:@"%d-%d-%d", level, row, col];
	image = [_recentTiles objectForKey:cacheIndex];
	if (nil != image) {
		return image;
	}
	 */
	
    // TODO: Don't save images as separate files. Save them in one flat file. The more files in an app, the longer it takes for a user to sync their device in iTunes.
    
	NSString* cacheFile = [self pathForTileAtLevel:level row:row col:col];
	cacheFile = [cacheFile stringByAppendingPathComponent:@"tile"];
	
    // get the image from disk if it was cached
	if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile])
	{
		NSData* data = [NSData dataWithContentsOfFile:cacheFile];
		image = [UIImage imageWithData:data];
	}
    // if image wasn't cached OR the cached file was not even a valid image (unless we only want to display cached images)
	if(!image && !onlyFromCache)
	{
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate showNetworkActivityIndicator];
#if 0
        NSString *sUrl = [NSString stringWithFormat:@"%@/%d.png", [[NSBundle mainBundle] resourcePath], level]; 
        NSURL *url = [NSURL fileURLWithPath:sUrl];
#else
        NSString* sUrl = [[_serviceURL absoluteString] stringByAppendingFormat:@"/tile2/%d/%d/%d", level, row, col];
        NSURL* url = [NSURL URLWithString:sUrl];
#endif
		NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
		
		NSError* error = nil;
		NSURLResponse* response = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
        [appDelegate hideNetworkActivityIndicator];
		[request release];
		
		if (data && [data length] > 0) {
			image = [UIImage imageWithData:data];
            // only cache valid images!
            if (image) {
                NSString *path = [self pathForTileAtLevel:level row:row col:col];
                
                SaveOperation *saveOperation = [[[SaveOperation alloc] initWithData:data
                                                                         saveToPath:path filename:@"tile" userData:nil] autorelease];
                saveOperation.delegate = self;
                [_saveOperationQueue addOperation:saveOperation];
            }
		}
	}

	// in memory cache.
	/*
	if (nil != image) {
		
		[_recentTilesIndex insertObject:cacheIndex atIndex:0];
		[_recentTiles setObject:image forKey:cacheIndex];
		if (_recentTilesIndex.count > kInMemoryTileLimit)
		{
			cacheIndex = [_recentTilesIndex lastObject];
			[_recentTiles removeObjectForKey:cacheIndex];
			[_recentTilesIndex removeLastObject];
		}

	}
	*/
	
	return image;
	
}

/*
#pragma mark PostDataDelegate
// data was received from the post data request. 
-(void) postData:(PostData*)postData receivedData:(NSData*) data
{
	if ([postData.api isEqualToString:@"mapTile"]) 
	{
		int row   = [[postData.userData objectForKey:@"row"] intValue];
		int col   = [[postData.userData objectForKey:@"col"] intValue];
		int level = [[postData.userData objectForKey:@"level"] intValue];
		

		
		// save it to the cache.
		NSString* path = [self pathForTileAtLevel:level row:row col:col];
		SaveOperation* saveOperation = [[[SaveOperation alloc] initWithData:data
																 saveToPath:path filename:@"tile" userData:postData.userData] autorelease];
		saveOperation.delegate = self;
		[_saveOperationQueue addOperation:saveOperation];
	}
}

// there was an error connecting to the specified URL. 
-(void) postData:(PostData*)postData error:(NSString*)error
{
	
}
*/
 
#pragma mark SaveOperationDelegate
-(void) saveOperationCompleteForFile:(NSString*)path withUserData:(NSDictionary*)userData
{
	/*
	int row   = [[userData objectForKey:@"row"] intValue];
	int col   = [[userData objectForKey:@"col"] intValue];
	int level = [[userData objectForKey:@"level"] intValue];
	
	UIImage* image = [UIImage imageWithContentsOfFile:path];
	
	// tell the delegate about it
	[self.delegate tileReceived:image forLevel:level row:row col:col];
	 */
}

#pragma mark CALayerDelegate
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	CGRect clipBox = CGContextGetClipBoundingBox(ctx);
	CGContextSetRGBFillColor(ctx, 193.0/255, 191.0/255, 187.0/255, 1.0);
	CGContextFillRect(ctx, clipBox);
	
	CGContextTranslateCTM( ctx, 0, CGRectGetMaxY( clipBox ) );
	CGContextScaleCTM( ctx, 1.0, -1.0 );
	CGRect rect = CGRectOffset( clipBox, 0, -clipBox.origin.y );
	
	// determine the level index from the size of tile being requested
	int rootLevel = log2(kTileSize); //8
	int currentLevel = log2(rect.size.width);
	int currentLevelIndex = rootLevel - currentLevel;
	
	MapLevel* currentMapLevel = [self.mapLevels objectAtIndex:currentLevelIndex];
	MapLevel* rootMapLevel    = [self.mapLevels objectAtIndex:0];
	
	// comute the cell that would be displayed at the root level
	int rootRow = rootMapLevel.minRow + clipBox.origin.y / kTileSize;
	int rootCol = rootMapLevel.minCol + clipBox.origin.x / kTileSize;
	
	// determine the cell that corresponds to on the current level
	int row = rootRow * pow(2, currentLevelIndex);
	int col = rootCol * pow(2, currentLevelIndex);
	
	// the pixel xy of the root cell
	int xRoot = (rootCol - rootMapLevel.minCol) * kTileSize;
	int yRoot = (rootRow - rootMapLevel.minRow) * kTileSize;
	
	// how far into our root cell is the data being requested
	int xOffset = clipBox.origin.x - xRoot;
	int yOffset = clipBox.origin.y - yRoot;
	
	int colOffset = xOffset / rect.size.width;
	int rowOffset = yOffset / rect.size.height;
	
	row += rowOffset;
	col += colOffset;
	
	
	UIImage* image = [[MapTileCache cache] getTileForLevel:currentMapLevel.level row:row col:col];
	
	
	if (image) 
	{
		CGContextDrawImage(ctx, rect, image.CGImage);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DrewTile"
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentMapLevel.level], @"level",
																[NSNumber numberWithInt:row], @"row",
																[NSNumber numberWithInt:col], @"col",
																nil, nil]];
																									
	
	
}

-(NSString*) mapTimestampFilename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:@"mapTimestamp.plist"];	
}

#pragma mark JSONLoadedDelegate
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{
	NSDictionary* dictionary = (NSDictionary*)JSONObject;
	
	long long newMapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
	
	if (newMapTimestamp != _mapTimestamp) 
	{
		DLog(@"New tiles on server. Wiping out map cache");
		
		// store the new timestamp and wipe out the cache.
		[dictionary writeToFile:[self mapTimestampFilename] atomically:YES];
		
		NSString* tileCachePath = [MapTileCache tileCachePath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileCachePath]) {
            NSError* error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:tileCachePath error:&error];
            
            if(nil != error)
            {
                ELog(@"Error wiping out map cache: %@", error);
            }
        }

		// send a notification to any observers that the map cache was reset. 
		[[NSNotificationCenter defaultCenter] postNotificationName:MapCacheReset object:self];
	}
}

- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	DLog(@"Check tile update failed. ");	
}

@end
