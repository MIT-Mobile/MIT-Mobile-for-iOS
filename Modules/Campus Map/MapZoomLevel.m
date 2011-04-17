#import "MapZoomLevel.h"
#import "MITProjection.h"
#import "SaveOperation.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileServerConfiguration.h"

@implementation MapTile
@synthesize path = _path, frame = _frame;

- (id)initWithFrame:(MKMapRect)frame path:(NSString *)path {
    self = [super init];
    if (self) {
        self.frame = frame;
        self.path = path;
    }
    return self;
}

- (void)dealloc {
    self.path = nil;
    [super dealloc];
}

@end


@implementation MapZoomLevel
@synthesize level, resolution, scale, maxCol, maxRow, minCol, minRow, zoomScale;

- (CGSize)totalSizeInPixels {
    CGSize size;
    size.width = [self tilesPerCol] * [[MITMKProjection sharedProjection] tileWidth] * zoomScale;
    size.height = [self tilesPerCol] * [[MITMKProjection sharedProjection] tileHeight] * zoomScale;
    return size;
}

+ (NSString *)tileCachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    return [cachePath stringByAppendingPathComponent:@"tile"];
}

- (NSString *)pathForTileAtRow:(int)row col:(int)col {
    return [[MapZoomLevel tileCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d-%d-%d", self.level, row, col]];
}

- (MapTile *)tileForRow:(int)row col:(int)col {
    CGFloat pix = [[MITMKProjection sharedProjection] pixelsPerProjectedUnit];

    CGFloat tileWidthInMapPoints = self.resolution * [[MITMKProjection sharedProjection] tileWidth] * pix;
    CGFloat tileHeightInMapPoints = self.resolution * [[MITMKProjection sharedProjection] tileHeight] * pix;
    
    MKMapRect rect = MKMapRectMake(col * tileWidthInMapPoints, row * tileHeightInMapPoints, tileWidthInMapPoints, tileHeightInMapPoints);
    
    MapTile *tile = [[[MapTile alloc] initWithFrame:rect path:[self pathForTileAtRow:row col:col]] autorelease];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tile.path]) {
        NSString *sUrl = [NSString stringWithFormat:@"%@/map/tile2/%d/%d/%d", [MITMobileWebGetCurrentServerURL() absoluteString], level, row, col];
        NSURL *url = [NSURL URLWithString:sUrl];
        DLog(@"Requesting map tile: %@", sUrl);
        
        requesting = YES;
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate showNetworkActivityIndicator];
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
		
		NSError *error = nil;
		NSURLResponse *response = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[MapZoomLevel tileCachePath]]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:[MapZoomLevel tileCachePath] withIntermediateDirectories:NO attributes:nil error:&error];
        }
        
        requesting = NO;
        [appDelegate hideNetworkActivityIndicator];
		[request release];
        
		if (data && [data length] > 0) {
			UIImage *image = [UIImage imageWithData:data];
            // only cache valid images!
            if (image) {
                if (!_saveOperationQueue) {
                    _saveOperationQueue = [[NSOperationQueue alloc] init];
                }
                
                NSString *filename = [NSString stringWithFormat:@"%d-%d-%d", self.level, row, col];
                SaveOperation *saveOperation = [[[SaveOperation alloc] initWithData:data
                                                                         saveToPath:[MapZoomLevel tileCachePath]
                                                                           filename:filename
                                                                           userData:nil] autorelease];
                saveOperation.delegate = self;
                [_saveOperationQueue addOperation:saveOperation];
            }
		}
    }
    
    return tile;
}

- (NSArray *)tilesForMapRect:(MKMapRect)mapRect {
    // get everything in tile server's coordinate system
    CGPoint startPoint = [[MITMKProjection sharedProjection] projectedPointForMapPoint:mapRect.origin];
    NSInteger startCol = floor((startPoint.x - [[MITMKProjection sharedProjection] originX]) / [[MITMKProjection sharedProjection] tileWidth]) / self.resolution;
    NSInteger startRow = floor(([[MITMKProjection sharedProjection] originY] - startPoint.y) / [[MITMKProjection sharedProjection] tileHeight]) / self.resolution;

    CGPoint endPoint = [[MITMKProjection sharedProjection] projectedPointForMapPoint:MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)];
    NSInteger endCol = ceil((endPoint.x - [[MITMKProjection sharedProjection] originX]) / [[MITMKProjection sharedProjection] tileWidth]) / self.resolution;
    NSInteger endRow = ceil(([[MITMKProjection sharedProjection] originY] - endPoint.y) / [[MITMKProjection sharedProjection] tileHeight]) / self.resolution;

    NSMutableArray *tiles = [NSMutableArray arrayWithCapacity:(endRow - startRow + 1) * (endCol - startCol + 1)];
    for (NSInteger row = startRow; row <= endRow; row++) {
        for (NSInteger col = startCol; col <= endCol; col++) {
            MapTile *tile = [self tileForRow:row col:col];
            [tiles addObject:tile];
        }
    }
    return [NSArray arrayWithArray:tiles];
}

- (NSInteger)tilesPerRow {
    return maxRow - minRow + 1;
}

- (NSInteger)tilesPerCol {
    return maxCol - minCol + 1;
}

- (void)dealloc {
    if (requesting) {
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    }
    [_saveOperationQueue release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (\n"
            "level: %d, resolution: %.1f\n"
            "scale: %.5f, zoomScale: %.1f\n"
            "minCol: %d, maxCol: %d, minRow: %d, maxRow: %d\n"
            ")", [super description], level, resolution, scale, zoomScale, minCol, maxCol, minRow, maxRow];
}

#pragma mark SaveOperationDelegate

   - (void)saveOperationCompleteForFile:(NSString*)path withUserData:(NSDictionary*)userData
{
}

@end
