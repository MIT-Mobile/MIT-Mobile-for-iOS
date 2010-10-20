
#import <Foundation/Foundation.h>

#import "SaveOperation.h"

@interface MapTileCache : NSObject  <SaveOperationDelegate> {

	// map service URL from where we will pull map cells
	NSURL* _serviceURL;
	
	//id<MapTileDelegate> _delegate;

	NSOperationQueue* _saveOperationQueue;
	
	NSArray* _mapLevels;
	
	NSMutableDictionary* _recentTiles;
	NSMutableArray* _recentTilesIndex;
	
	NSMutableArray* _registeredDelegates;
}

@property (nonatomic, retain) NSURL* serviceURL;
//@property (assign) id<MapTileDelegate> delegate;
@property (nonatomic, retain) NSArray* mapLevels;


+(NSString*) tileCachePath;

+(MapTileCache*) cache;

-(NSString*) pathForTileAtLevel:(int)level row:(int)row col:(int)col;

-(UIImage*) getTileForLevel:(int)level row:(int)row col:(int)col;

// get the tile but only if it is in the cache (depending on onlyFromCache bool)
-(UIImage*) getTileForLevel:(int)level row:(int)row col:(int)col onlyFromCache:(BOOL)onlyFromCache;

@end
