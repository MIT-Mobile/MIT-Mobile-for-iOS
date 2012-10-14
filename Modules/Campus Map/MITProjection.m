#import <MapKit/MapKit.h>
#import "MITProjection.h"
#import "MapZoomLevel.h"
#import "MITMapView.h"

#define TILE_SIZE 256 // Pixel dimensions of map tiles. Square tiles assumed.
#define MAX_ZOOM_LEVEL 20 // Google Maps style levels of zoom. Powers of two. Circumference of the world == TILE_SIZE * (2 ** zoom)

@implementation MITProjection

#pragma mark -
#pragma mark Singleton Boilerplate

static MITProjection *sharedProjection = nil;

+ (MITProjection *)sharedProjection
{
	if (sharedProjection == nil) {
		sharedProjection = [[MITProjection alloc] init];
	}
	
	return sharedProjection;
}


#pragma mark -
#pragma mark Initialization

- (id) init
{
    self = [super init];
    if (self) {
        NSInteger err = 0;
        tileSize = TILE_SIZE;
        maxZoomLevel = MAX_ZOOM_LEVEL;
        if (!err) {
            pixelsPerDegreeLongitude = malloc(sizeof(CGFloat) * (maxZoomLevel + 1));
            if (pixelsPerDegreeLongitude == NULL) { err = ENOMEM; }
        }
        if (!err) {
            radiusOfTheEarth = malloc(sizeof(CGFloat) * (maxZoomLevel + 1));
            if (radiusOfTheEarth == NULL) { err = ENOMEM; }
        }
        if (!err) {
            centerPointOfTheEarth = malloc(sizeof(CGPoint) * (maxZoomLevel + 1));
            if (centerPointOfTheEarth == NULL) { err = ENOMEM; }
        }
        if (!err) {
            circumferenceOfTheEarth = malloc(sizeof(NSInteger) * (maxZoomLevel + 1));
            if (circumferenceOfTheEarth == NULL) { err = ENOMEM; }
        }
        // precalculate a few expressions for each zoom level
        if (!err) {
            // d == zoom level (0 - 20)
            // c == circumference of the Earth at this zoom level
            for (NSInteger c = tileSize, d = 0; d <= maxZoomLevel; d++) {
                CGFloat halfC = c / 2.0;
                pixelsPerDegreeLongitude[d] = c / 360.0;
                radiusOfTheEarth[d] = c / (2 * M_PI);
                centerPointOfTheEarth[d] = CGPointMake(halfC, halfC);
                circumferenceOfTheEarth[d] = c;
                c *= 2;
            }
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (pixelsPerDegreeLongitude) {
        free(pixelsPerDegreeLongitude);
        pixelsPerDegreeLongitude = NULL;
    }
    if (radiusOfTheEarth) {
        free(radiusOfTheEarth);
        radiusOfTheEarth = NULL;
    }
    if (centerPointOfTheEarth) {
        free(centerPointOfTheEarth);
        centerPointOfTheEarth = NULL;
    }
    if (circumferenceOfTheEarth) {
        free(circumferenceOfTheEarth);
        circumferenceOfTheEarth = NULL;
    }
    [super dealloc];
}

#pragma mark -
#pragma mark Projections

+ (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel {
    return [[MITProjection sharedProjection] pixelPointForCoord:lnglat zoomLevel:zoomLevel];
}

+ (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel {
    return [[MITProjection sharedProjection] coordForPixelPoint:pixelPoint zoomLevel:zoomLevel];
}

- (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel {
    CGFloat x = round(centerPointOfTheEarth[zoomLevel].x + (lnglat.longitude * pixelsPerDegreeLongitude[zoomLevel]));
    CGFloat a = MIN(MAX(sin(lnglat.latitude * M_PI / 180.0), -0.9999), 0.9999); // used twice, calculate once
    CGFloat y = round(centerPointOfTheEarth[zoomLevel].y + (0.5 * log((1 + a) / (1 - a))) * -radiusOfTheEarth[zoomLevel]);
    return CGPointMake(x, y);
}

- (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel {
    
	CLLocationCoordinate2D coordinate;
	
	coordinate.longitude = (pixelPoint.x - centerPointOfTheEarth[zoomLevel].x) / pixelsPerDegreeLongitude[zoomLevel];
    coordinate.latitude = (2 * atan(exp((pixelPoint.y - centerPointOfTheEarth[zoomLevel].y) / -radiusOfTheEarth[zoomLevel])) - M_PI_2) / (M_PI / 180);
    
    return coordinate;
}

@end

@interface MITMKProjection (Private)

- (void)saveData;
- (BOOL)setupServerInfo:(NSDictionary *)serverInfo;

@end

static MITMKProjection *s_projection = nil;
static NSString * kTileServerFilename = @"tileServer.plist";
static NSString * kMapTimestampFilename = @"mapTimestamp.plist";
static NSString * kLastUpdatedKey = @"lastupdated";
static NSString * kMapPathExtension = @"map/";

@implementation MITMKProjection

+ (MITMKProjection *)sharedProjection {
    if (s_projection == nil) {
        s_projection = [[MITMKProjection alloc] init];
    }
    return s_projection;
}

- (id)init {
    self = [super init];
    if (self) {
        BOOL didSetup = NO;
        
        _observers = [[NSMutableArray alloc] init];
        
        NSString *filename = [MITMKProjection serverInfoFilename];
        _serverInfo = [[NSMutableDictionary dictionaryWithContentsOfFile:filename] retain];
        
        if (_serverInfo != nil) {
            NSDate *date = [_serverInfo objectForKey:kLastUpdatedKey];
            if ([[NSDate date] timeIntervalSinceDate:date] <= 1) {
                didSetup = [self setupServerInfo:_serverInfo];
            }
        }
        
        if (!didSetup) {
            MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
            api.userData = @"capabilities";
            [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"serviceinfo", @"command", nil] pathExtension:kMapPathExtension];
        }
        
        // handle last update
        
		NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:[MITMKProjection mapTimestampFilename]];
		_mapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
        
        MITMobileWebAPI *updateRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
        updateRequest.userData = kLastUpdatedKey;
        [updateRequest requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"tilesupdated", @"command", nil] pathExtension:kMapPathExtension];
    }
    return self;
}

- (CGFloat)maximumZoomScale {
    return _maximumZoomScale;
}

- (CGFloat)minimumZoomScale {
    return _minimumZoomScale;
}

- (NSArray *)mapLevels {
    return _mapLevels;
}

- (CGFloat)tileWidth {
    return _tileWidth;
}

- (CGFloat)tileHeight {
    return _tileHeight;
}

+ (NSString *)serverInfoFilename {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:kTileServerFilename];
}

+ (NSString*)mapTimestampFilename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentPath = [paths objectAtIndex:0];
	return [documentPath stringByAppendingPathComponent:kMapTimestampFilename];	
}

+ (NSString *)tileCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* cachePath = [paths objectAtIndex:0];
	return [cachePath stringByAppendingPathComponent:@"tile"];
}

- (void)saveData {
	NSString *filename = [MITMKProjection serverInfoFilename];
	BOOL saved = [_serverInfo writeToFile:filename atomically:YES];
	DLog(@"Saved file: %@ %@", filename, saved ? @"SUCCESS" : @"FAIL");
    if (!saved) {
        ELog(@"could not save file with contents %@", [_serverInfo description]);
    }
}

- (MapZoomLevel *)rootMapLevel {
    return _baseMapLevel;
}

- (MapZoomLevel *)highestMapLevel {
    return (MapZoomLevel *)[_mapLevels lastObject];
}

- (CLLocationCoordinate2D)southEastBoundary {
    CGPoint topLeftProjectedPoint = CGPointMake(_xMax, _yMax);
    NSError *error = nil;
    CLLocationCoordinate2D se = [self coordForProjectedPoint:topLeftProjectedPoint error:&error];
    return se;
}

- (CLLocationCoordinate2D)northWestBoundary {
    CGPoint topLeftProjectedPoint = CGPointMake(_xMin, _yMin);
    NSError *error = nil;
    CLLocationCoordinate2D nw = [self coordForProjectedPoint:topLeftProjectedPoint error:&error];
    return nw;
}

- (MKCoordinateRegion)defaultRegion {
    if (_serverInfo) {
        if (_defaultRegion.span.latitudeDelta == 0) {
            NSError *error = nil;
            CGPoint point = CGPointMake((_defaultXMin + _defaultXMax) / 2,
                                        (_defaultYMin + _defaultYMax) / 2);
            CLLocationCoordinate2D centerCoord = [self coordForProjectedPoint:point error:&error];
            
            point = CGPointMake(_defaultXMax, _defaultYMax);
            CLLocationCoordinate2D cornerCoord = [self coordForProjectedPoint:point error:&error];
            
            // the initialExtent returned by the harvard server is really zoomed in
            // so we increase the span a little
            MKCoordinateSpan span = MKCoordinateSpanMake((cornerCoord.latitude - centerCoord.latitude) * 4,
                                                         (cornerCoord.longitude - centerCoord.longitude) * 4);
            
            _defaultRegion = MKCoordinateRegionMake(centerCoord, span);
        }
        return _defaultRegion;
    } else {
        return MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
    }
}

- (MKMapRect)mapRectForFullExtent {
    if (!_mapRectForFullExtent.size.width) {
        CGPoint nw = CGPointMake(_xMin, _yMax);
        CGPoint se = CGPointMake(_xMax, _yMin);
        MKMapPoint neMapPoint = [self mapPointForProjectedPoint:nw];
        MKMapPoint seMapPoint = [self mapPointForProjectedPoint:se];
        _mapRectForFullExtent = MKMapRectMake(neMapPoint.x,
                                              neMapPoint.y,
                                              seMapPoint.x - neMapPoint.x,
                                              seMapPoint.y - neMapPoint.y);
    }
    return _mapRectForFullExtent;
}

- (CGFloat)originX {
    return _originX;
}

- (CGFloat)originY {
    return _originY;
}

- (CGFloat)circumferenceInProjectedUnits {
    return _circumferenceInProjectedUnits;
}

- (CGFloat)meridianLengthInProjectedUnits {
    return _meridianLengthInProjectedUnits;
}

// TODO: add NSError argument if conversion fails
- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord error:(NSError **)error {
    CGFloat x = coord.longitude / 360.0 * _circumferenceInProjectedUnits;
    CGFloat y = _radiusInProjectedUnits * log(tan(M_PI / 4 + coord.latitude / 2)) * RADIANS_PER_DEGREE;
    return CGPointMake(x, y);
}

- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point error:(NSError **)error {
    CLLocationCoordinate2D coord;
    coord.longitude = point.x / _circumferenceInProjectedUnits * 360.0;
    coord.latitude = 2 * (atan(exp(point.y / _radiusInProjectedUnits)) - M_PI / 4) * DEGREES_PER_RADIAN;
    return coord;
}

- (BOOL)setupServerInfo:(NSMutableDictionary *)serverInfo {
    NSInteger rootLevel = 0;
    
    NSArray *layers = [serverInfo objectForKey:@"layers"];
    if (!layers)
        return NO;
    
    NSMutableArray *cleanedUpLayers = [NSMutableArray arrayWithCapacity:[layers count]];
    for (NSDictionary *layerInfo in layers) {
        NSMutableDictionary *cleanedUpLayerInfo = [NSMutableDictionary dictionaryWithDictionary:layerInfo];
        [cleanedUpLayerInfo removeObjectForKey:@"subLayerIds"];
        [cleanedUpLayers addObject:cleanedUpLayerInfo];
    }
    [serverInfo setObject:cleanedUpLayers forKey:@"layers"];
    
    NSDictionary *extent = [serverInfo objectForKey:@"fullExtent"];
    _xMax = [[extent objectForKey:@"xmax"] doubleValue];
    _xMin = [[extent objectForKey:@"xmin"] doubleValue];
    _yMax = [[extent objectForKey:@"ymax"] doubleValue];
    _yMin = [[extent objectForKey:@"ymin"] doubleValue];
    
    // one-time values for calculation of defaultRegion
    extent = [serverInfo objectForKey:@"initialExtent"];
    _defaultXMax = [[extent objectForKey:@"xmax"] doubleValue];
    _defaultXMin = [[extent objectForKey:@"xmin"] doubleValue];
    _defaultYMax = [[extent objectForKey:@"ymax"] doubleValue];
    _defaultYMin = [[extent objectForKey:@"ymin"] doubleValue];
    
    NSDictionary *tileInfo = [serverInfo objectForKey:@"tileInfo"];
    _tileHeight = [[tileInfo objectForKey:@"rows"] doubleValue];
    _tileWidth = [[tileInfo objectForKey:@"cols"] doubleValue];
    
    NSDictionary *origin = [tileInfo objectForKey:@"origin"];
    _originX = [[origin objectForKey:@"x"] doubleValue];
    _originY = [[origin objectForKey:@"y"] doubleValue];
    
    // take care of map levels
    
    // tile (row|col) by pixels per projected unit
    CGFloat minRowInProjectedUnits = (_originY - _yMax) / _tileHeight;
    CGFloat minColInProjectedUnits = (_xMin - _originX) / _tileWidth;
    CGFloat maxRowInProjectedUnits = (_originY - _yMin) / _tileHeight;
    CGFloat maxColInProjectedUnits = (_xMax - _originX) / _tileWidth;
    
    _circumferenceInProjectedUnits = -2.0 * _originX;
    _pixelsPerProjectedUnit = MKMapSizeWorld.width / _circumferenceInProjectedUnits;
    _radiusInProjectedUnits = _circumferenceInProjectedUnits / (2 * M_PI);
    _meridianLengthInProjectedUnits = MKMapSizeWorld.height / _pixelsPerProjectedUnit;
    
    NSArray *levelsOfDetail = [tileInfo objectForKey:@"lods"];
    NSMutableArray *zoomLevels = [NSMutableArray arrayWithCapacity:[levelsOfDetail count]];

    // TODO: find a way to ignore zoom levels below 13
    for (NSDictionary *levelOfDetail in levelsOfDetail) {
        MapZoomLevel *zoomLevel = [[[MapZoomLevel alloc] init] autorelease];
        
        CGFloat resolution = [[levelOfDetail objectForKey:@"resolution"] doubleValue];
        zoomLevel.resolution = resolution;
        
        // TODO: figure out if these should use floor/ceil instead of round
        zoomLevel.minRow = round(minRowInProjectedUnits / resolution);
        zoomLevel.minCol = round(minColInProjectedUnits / resolution);
        zoomLevel.maxRow = round(maxRowInProjectedUnits / resolution);
        zoomLevel.maxCol = round(maxColInProjectedUnits / resolution);
        
        NSInteger level = [[levelOfDetail objectForKey:@"level"] intValue];
        zoomLevel.level = level;
        
        if (level == rootLevel) {
            _baseMapLevel = zoomLevel;
        }
        
        zoomLevel.scale = [[levelOfDetail objectForKey:@"scale"] floatValue];
        
        CGFloat numTilesAcrossEquator = _circumferenceInProjectedUnits / zoomLevel.resolution;
        zoomLevel.zoomScale = numTilesAcrossEquator / MKMapSizeWorld.width;
        
        [zoomLevels addObject:zoomLevel];
    }
    
    _mapLevels = [[NSArray arrayWithArray:zoomLevels] retain];
    
    if (_mapLevels.count) {
        _minimumZoomScale = [(MapZoomLevel *)[_mapLevels objectAtIndex:0] zoomScale];
        _maximumZoomScale = [(MapZoomLevel *)[_mapLevels lastObject] zoomScale];
    }
    
    for (MITMapView *anObserver in _observers) {
        [anObserver enableProjectedFeatures];
    }
    [_observers release];
    _observers = nil;
    
    return YES;
}

- (CGFloat)pixelsPerProjectedUnit {
    return _pixelsPerProjectedUnit;
}
    
- (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint {
    CGPoint point;
    point.x = mapPoint.x / _pixelsPerProjectedUnit + _originX;
    point.y = _originY - mapPoint.y / _pixelsPerProjectedUnit;
    return point;
}

- (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point {
    MKMapPoint mapPoint;
    mapPoint.x = (point.x - _originX) * _pixelsPerProjectedUnit;
    mapPoint.y = (_originY - point.y) * _pixelsPerProjectedUnit;
    return mapPoint;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
    if ([request.userData isEqualToString:kLastUpdatedKey]) {
        NSDictionary* dictionary = (NSDictionary *)result;
        long long newMapTimestamp = [[dictionary objectForKey:kLastUpdatedKey] longLongValue];
        
        if (newMapTimestamp != _mapTimestamp) {
            // store the new timestamp and wipe out the cache.
            DLog(@"New map tiles found. New timestamp: %lld Old timestamp: %lld", newMapTimestamp, _mapTimestamp);
            [dictionary writeToFile:[MITMKProjection mapTimestampFilename] atomically:YES];
            
            NSString* tileCachePath = [MITMKProjection tileCachePath];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:tileCachePath]) {
                NSError* error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:tileCachePath error:&error]) {
                    ELog(@"Error wiping out map cache: %@", error);
                }
            }
        }
        
    } else {
        _serverInfo = [[NSMutableDictionary alloc] initWithDictionary:result];
        [_serverInfo setObject:[NSDate date] forKey:kLastUpdatedKey];
        
        [self setupServerInfo:_serverInfo];
        
    }
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return NO;
}

- (void)request:(MITMobileWebAPI *)request handleConnectionError:(NSError *)error {
    ELog(@"failed to get tile server info");
	// TODO: handle connection failure
}

- (void)addObserver:(MITMapView *)observer {
    if (_observers) {
        [_observers addObject:observer];
    }
    else if (_serverInfo) {
        [observer enableProjectedFeatures];
    }
}

- (void)dealloc {
    [_mapLevels release];
    [_serverInfo release];
    [super dealloc];
}

@end
