
#import "MITMapView.h"
#import "MapLevel.h"
#import "MITMapUserLocation.h"
#import "MITMapSearchResultAnnotation.h"
#import "NSString+SBJSON.h"
#import "RouteView.h"

#define kTileSize 256
#define LogRect(rect, message) NSLog(@"%@ rect: %f %f %f %f", message,  rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)


@interface MITMapView(Private) 

-(void) createSubviews;

-(void) positionAnnotationViews;

-(void) positionCurrentCallout;

-(void) onscreenTilesLevel:(int*)level minRow:(int*)minRow minCol:(int*)minCol maxRow:(int*)maxRow maxCol:(int*)maxCol;

-(void) removePreloadedTile:(NSString*)index;

// get the tiles that should be onscreen. Tiles are returned as dictionaries with level, row and col values. 
-(void) onscreenTilesLevel:(int*)level row:(int*)row col:(int*)col;

@end

@implementation MITMapView
@synthesize mapLevels = _mapLevels;
@synthesize showsUserLocation = _showsUserLocation;
@synthesize stayCenteredOnUserLocation = _stayCenteredOnUserLocation;
@synthesize delegate = _mapDelegate;


- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	self.mapLevels = nil;
	
	[_mapContentView release];
	
	_scrollView.delegate = nil;	
	[_scrollView release];
	
	[_tiledLayer release];
	
	[_locationView release];
	
	[_locationManager release];
	
	[_userLocationAnnotation release];
	
	[_annotationViews release];

	[_annotations release];
	
	[_routes release];
	
	[_preloadedLayers release];
	
	[_currentCallout release];
		
	[_routeView release];
	
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) 
	{
		[self createSubviews];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	if(self = [super initWithCoder:aDecoder])
	{
		[self createSubviews];
	}
	
	return self;
}

-(void) layoutSubviews
{
	if (nil == _scrollView) {
		//[self createSubviews];
	}
	
}

-(void) preloadTileAtLevel:(int)level row:(int)row col:(int)col
{
	
	UIImage* tile = [[MapTileCache cache] getTileForLevel:level row:row col:col onlyFromCache:YES];
	if (nil != tile) {
		
		MapLevel* rootMapLevel = [self.mapLevels objectAtIndex:0];
		int levelIndex = level - rootMapLevel.level;
		
		//MapLevel* mapLevel = [self.mapLevels objectAtIndex:levelIndex];
		CGFloat levelTileSize = kTileSize / pow(2, levelIndex);
		
		
		// determine the corresponding root tile 
		int rootRow = row / pow(2, levelIndex);
		int rootCol = col / pow(2, levelIndex);
		
		// determine where that root tile would be in xy
		int rootX = (rootCol - rootMapLevel.minCol) * kTileSize;
		int rootY = (rootRow - rootMapLevel.minRow) * kTileSize;
		
		// determine the col and row offset into the root for this level
		int rowOffset = row - rootRow * pow(2, levelIndex);
		int colOffset = col - rootCol * pow(2, levelIndex);
		
		
		int x = rootX + colOffset * levelTileSize;
		int y = rootY + rowOffset * levelTileSize;
			

		//add the tile. 
		UIImageView* imageView = [[UIImageView alloc] initWithImage:tile];
		imageView.frame = CGRectMake(x, y, levelTileSize, levelTileSize);
		
		//imageView.layer.anchorPoint = CGPointMake(0, 0);
		//imageView.layer.position = CGPointMake(x, y);
		imageView.opaque = NO;
		[_tiledLayer addSublayer:imageView.layer];
		
		if (nil == _preloadedLayers) {
			_preloadedLayers = [[NSMutableDictionary alloc] initWithCapacity:4];
		}
		
		NSString* index = [NSString stringWithFormat:@"%d-%d-%d", level, row, col];
		[_preloadedLayers setObject:[imageView autorelease] forKey:index];
	}

}

-(void) removePreloadedTile:(NSString*)index
{
	UIImageView* view = [_preloadedLayers objectForKey:index];
	
	[view.layer performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:[CATiledLayer fadeDuration] * 2];
	
	[_preloadedLayers removeObjectForKey:index];	
	
	if (_preloadedLayers.count <= 0) {
		[_preloadedLayers release];
		_preloadedLayers = nil;
	}
	
}

-(void) drewTile:(NSNotification*) notification
{
	
	if (nil != _preloadedLayers && _preloadedLayers.count > 0) 
	{
		NSDictionary* userInfo = notification.userInfo;
		int level = [[userInfo objectForKey:@"level"] intValue];
		int row   = [[userInfo objectForKey:@"row"] intValue];
		int col   = [[userInfo objectForKey:@"col"] intValue];
		
		NSString* index = [NSString stringWithFormat:@"%d-%d-%d", level, row, col];
		UIImageView* view = [_preloadedLayers objectForKey:index];
		
		if (nil != view) {
			[self performSelectorOnMainThread:@selector(removePreloadedTile:) withObject:index waitUntilDone:YES];

		}
	}
	
}

-(void) createSubviews
{
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drewTile:) name:@"DrewTile" object:nil];
	
	self.multipleTouchEnabled = YES;
	self.clipsToBounds = YES;
	// create the background color pattern
	UIImage* gridImage = [UIImage imageNamed:@"map_grid_placeholder.png"];
	UIColor* gridColor = [UIColor colorWithPatternImage:gridImage];

	
	UIColor* grayGridColor = [UIColor colorWithRed:193.0/255 green:191.0/255 blue:187.0/255 alpha:1.0];
	self.backgroundColor = grayGridColor;
	
	
	//
	// load the map levels. 
	//
	NSString* path = [[NSBundle mainBundle] pathForResource:@"MapLevels" ofType:@"plist" inDirectory:@"Modules/Campus Map"];
	NSDictionary* mapInfo = [NSDictionary dictionaryWithContentsOfFile:path];
	
	NSArray* levels = [mapInfo objectForKey:@"MapLevels"];
	
	NSMutableArray* mapLevels = [NSMutableArray arrayWithCapacity:levels.count];
	for (NSDictionary* levelInfo in levels) {
		MapLevel* level = [MapLevel levelWithInfo:levelInfo];
		[mapLevels addObject:level];
	}
	
	self.mapLevels = mapLevels;
	_scrollView.maximumZoomScale = pow(2, self.mapLevels.count);
	
	CLLocationCoordinate2D initialLocation;
	NSDictionary* initialLocationInfo = [mapInfo objectForKey:@"InitialLocation"];
	
	initialLocation.latitude = [[initialLocationInfo objectForKey:@"Latitude"] doubleValue];
	initialLocation.longitude = [[initialLocationInfo objectForKey:@"Longitude"] doubleValue];
	
	CGFloat initialZoom = [[initialLocationInfo objectForKey:@"Zoom"] doubleValue];
	
	// set the service url so the cache can download tiles. 
	[MapTileCache cache].serviceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MITMobileWebAPIURLString, @"map"]];
	//[MapTileCache cache].delegate = self;								   
	
	MapLevel* currentMapLevel = [self.mapLevels objectAtIndex:0];
	
	CGRect pageRect = CGRectMake(0, 0, currentMapLevel.cols * kTileSize, currentMapLevel.rows * kTileSize);
	
	_tiledLayer = [[CATiledLayer alloc] init];//[[FastCATiledLayer layer] retain];
	_tiledLayer.delegate = [MapTileCache cache];
	//_tiledLayer.tileSize = CGSizeMake(kTileSize * 2, kTileSize * 2);
	_tiledLayer.tileSize = CGSizeMake(kTileSize, kTileSize);
	_tiledLayer.levelsOfDetail = self.mapLevels.count;
	_tiledLayer.levelsOfDetailBias = self.mapLevels.count - 1;
	_tiledLayer.frame = pageRect;
	_tiledLayer.opaque = YES;

	_tiledLayer.backgroundColor = gridColor.CGColor;

	_mapContentView = [[UIView alloc] initWithFrame:pageRect];
	[_mapContentView.layer addSublayer:_tiledLayer];
	
	
	CGRect viewFrame = self.frame;
	viewFrame.origin = CGPointZero;
	_scrollView = [[MITMapScrollView alloc] initWithFrame:viewFrame];
	_scrollView.delegate = self;
	_scrollView.contentSize = pageRect.size;
	_scrollView.maximumZoomScale = pow(2 , self.mapLevels.count - 1);
	_scrollView.minimumZoomScale = 1;// / pow(2, self.mapLevels.count);
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	_scrollView.multipleTouchEnabled = YES;
	_scrollView.backgroundColor = grayGridColor;
	_scrollView.opaque = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
	_scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	[_scrollView addSubview:_mapContentView];


	[self addSubview:_scrollView];
	
	// move to the initial point
	_scrollView.zoomScale = initialZoom;
	[self setCenterCoordinate:initialLocation animated:NO];
	
	// copute the grographic range of the map. 
	_nw = [self coordinateForScreenPoint:CGPointMake(0, 0)];
	_se = [self coordinateForScreenPoint:CGPointMake(_tiledLayer.frame.size.width, _tiledLayer.frame.size.height)];
	
	int level, minRow, minCol, maxRow, maxCol;
	[self onscreenTilesLevel:&level minRow:&minRow minCol:&minCol maxRow:&maxRow maxCol:&maxCol];
	
	for (int row = minRow; row <= maxRow; row++) 
	{
		for (int col = minCol; col <= maxCol; col++) 
		{
			[self preloadTileAtLevel:level row:row col:col];
		}
	}
		
	if(nil != _locationView)
	{
		[self bringSubviewToFront:_locationView];
	}
	
	// Subscribe to notifications of tapping an annotation.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationTapped:) name:kMITMapAnnotationViewTapped object:nil];
}

-(void) onscreenTilesLevel:(int*)level minRow:(int*)minRow minCol:(int*)minCol maxRow:(int*)maxRow maxCol:(int*)maxCol
{
	
	MapLevel* rootMapLevel = [self.mapLevels objectAtIndex:0];

	// get the unscaled values
	CGFloat zoom = _scrollView.zoomScale;
	CGPoint offset = _scrollView.contentOffset;
	CGRect unscaledRect = CGRectMake(offset.x / zoom, offset.y / zoom, self.frame.size.width / zoom, self.frame.size.height / zoom);
	
	// determine our level index. 
	int levelIndex = (int)floor(zoom) - 1;
	if (levelIndex > _mapLevels.count) {
		levelIndex = _mapLevels.count - 1;
	}
	else if(levelIndex < 0)
		levelIndex = 0;
	
	MapLevel* mapLevel = [self.mapLevels objectAtIndex:levelIndex];
	*level = mapLevel.level;
	
	int tileSizeAtLevel = kTileSize / pow(2, levelIndex);
	
	// determine the root tiles that would get loaded. 
	int rootMinCol = rootMapLevel.minCol + (unscaledRect.origin.x / kTileSize);
	int rootMinRow = rootMapLevel.minRow + (unscaledRect.origin.y / kTileSize);
	
	/*
	int rootMaxCol = rootMinCol + ((unscaledRect.size.width - kTileSize) / kTileSize);
	int rootMaxRow = rootMinRow + ((unscaledRect.size.height - kTileSize) / kTileSize);
	
	if (rootMaxCol < rootMinCol) rootMaxCol = rootMinCol;
	if (rootMaxRow < rootMinRow) rootMaxRow = rootMinRow;
	*/
	
	// determine the rootX and rootY
	int rootMinX = (rootMinCol - rootMapLevel.minCol) * kTileSize;
	int rootMinY = (rootMinRow - rootMapLevel.minRow) * kTileSize;
	
	// determine how far into the root cell our view lies
	int levelOffsetX = unscaledRect.origin.x - rootMinX;
	int levelOffsetY = unscaledRect.origin.y - rootMinY;
	
	*minCol = rootMinCol * pow(2, levelIndex) + levelOffsetX / tileSizeAtLevel;
	*minRow = rootMinRow * pow(2, levelIndex) + levelOffsetY / tileSizeAtLevel;
	
	*maxCol = *minCol + (unscaledRect.size.width / tileSizeAtLevel);
	*maxRow = *minRow + (unscaledRect.size.height / tileSizeAtLevel);
	
}

-(BOOL) scrollEnabled
{
	return _scrollView.scrollEnabled;
}
-(void) setScrollEnabled:(BOOL) scrollEnabled
{
	_scrollView.scrollEnabled = scrollEnabled;
}


-(CGPoint) unscaledScreenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
	MapLevel* rootLevel = [self.mapLevels objectAtIndex:0];
	int worldOffsetX = rootLevel.minCol * kTileSize;
	int worldOffsetY = rootLevel.minRow * kTileSize;
	
	// get the world pixel coordinates from our projection
	CGPoint worldPoint = [MITProjection pixelPointForCoord:coordinate zoomLevel:rootLevel.level];
	
	// subtract the world reference of our first tiles
	return CGPointMake((int)round(worldPoint.x) - worldOffsetX, (int)round(worldPoint.y) - worldOffsetY);
	
}

-(CGPoint) screenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
	CGPoint point = [self unscaledScreenPointForCoordinate:coordinate];
	

	CGFloat zoomScale = _scrollView.zoomScale;

	point = CGPointMake((int)round(point.x * zoomScale - _scrollView.contentOffset.x),
											   (int)round(point.y * zoomScale - _scrollView.contentOffset.y));
	
	return point;
}

-(CLLocationCoordinate2D) coordinateForScreenPoint:(CGPoint) point
{
	MapLevel* rootLevel = [self.mapLevels objectAtIndex:0];
	int worldOffsetX = rootLevel.minCol * kTileSize;
	int worldOffsetY = rootLevel.minRow * kTileSize;
	
	point.x += worldOffsetX;
	point.y += worldOffsetY;
	
	CLLocationCoordinate2D coordinate = [MITProjection coordForPixelPoint:point zoomLevel:rootLevel.level];
	
	return coordinate;
}


-(void) setShowsUserLocation:(BOOL)showsUserLocation
{
	_showsUserLocation = showsUserLocation;
	
	
	if (_showsUserLocation) 
	{
		if(nil == _locationManager)
		{
			_locationManager = [[CLLocationManager alloc] init];
		}
		
		[_locationManager setDelegate:self];
		[_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
		[_locationManager setDistanceFilter:kCLDistanceFilterNone];
		[_locationManager startUpdatingLocation];
		
		if (nil == _locationView) 
		{
			// create the location view and move it offscreen until a location is found
			_locationView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_location_complete.png"]];
			_locationView.frame = CGRectMake(-200, -200, _locationView.frame.size.width, _locationView.frame.size.height);
			[self.layer addSublayer:_locationView.layer];
			//[self addSubview:_locationView];				 
		}
	}
	else {
		[_locationView.layer removeFromSuperlayer];
		//[_locationView removeFromSuperview];
		[_locationView release];
		_locationView = nil;
		
		[_locationManager setDelegate:nil];
		[_locationManager stopUpdatingLocation];
		[_locationManager release];
		_locationManager = nil;
		
		[_userLocationAnnotation release];
		_userLocationAnnotation = nil;
	}
	
}

-(CGFloat) zoomLevel
{
	return _scrollView.zoomScale;
}

-(void) updateLocationIcon:(BOOL)scroll
{
	if (!self.showsUserLocation) {
		return;
	}
	
	CLLocationCoordinate2D coordinate = _userLocationAnnotation.coordinate;
	
	// determine pixel coordinates for our location relative to the full view of our map
	CGPoint mapPoint = [self unscaledScreenPointForCoordinate:coordinate];
	
	CGFloat zoomScale = _scrollView.zoomScale;
	
	_locationView.layer.position = CGPointMake(mapPoint.x * zoomScale - _scrollView.contentOffset.x,
											  mapPoint.y * zoomScale - _scrollView.contentOffset.y);
	
	
	// if we're centering on the user location, scroll to it here
	if (scroll && self.stayCenteredOnUserLocation) {
		
		// if the location is in bounds. 
		if (_nw.latitude > coordinate.latitude &&
			_se.latitude < coordinate.latitude &&
			_nw.longitude < coordinate.longitude &&
			_se.longitude > coordinate.longitude) 
		{
			[self setCenterCoordinate:coordinate animated:YES];
		}
	}
	
}

-(MITMapUserLocation*) userLocation
{
	MITMapUserLocation* userLocation = [[[MITMapUserLocation alloc] init] autorelease];
	if (nil != _locationManager) {
		CLLocation* location = _locationManager.location;
		if (location) 
		{
			[userLocation updateToCoordinate:_locationManager.location.coordinate];	
		}
		
	}
	
	return userLocation;
}


-(void) setStayCenteredOnUserLocation:(BOOL)centerOnUser
{
	_stayCenteredOnUserLocation = centerOnUser;
	
	if(_stayCenteredOnUserLocation)
	{
		CLLocationCoordinate2D coordinate =  _userLocationAnnotation.coordinate;
		
		//MITMapUserLocation* userLocation = self.userLocation;
		
		// if the user location is in bounds, center the map on the location. 
		// Otherwise, tell the user it is out of bounds. 
		if (_nw.latitude > coordinate.latitude &&
			_se.latitude < coordinate.latitude &&
			_nw.longitude < coordinate.longitude &&
			_se.longitude > coordinate.longitude) 
		{
			[self setCenterCoordinate:coordinate animated:YES];
		}
		else {
			_stayCenteredOnUserLocation = NO;

			// messages to be shown when user taps locate me button off campus
			NSString *message = nil;
			if (arc4random() & 1) {
				message = [NSString stringWithString:@"Unlike the Earth, MIT is flat. Apparently you have fallen off the edge of the MIT campus."];
			} else {
				message = [NSString stringWithString:@"The MIT Campus is only so large, and you are out of bounds. Here be dragons."];
			}
			
			UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Off Campus", nil)
															 message:message 
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"OK", nil)
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}


	}

}
#pragma mark Center coordinate property
-(void) setCenterCoordinate:(CLLocationCoordinate2D) coordinate animated:(BOOL)animated
{
	CGPoint point = [self unscaledScreenPointForCoordinate:coordinate];
	
	CGFloat width  = _scrollView.frame.size.width;// / _scrollView.zoomScale;
	CGFloat height = _scrollView.frame.size.height;// / _scrollView.zoomScale;
	
	CGRect centeredRect = CGRectMake(point.x * _scrollView.zoomScale - width / 2,
									 point.y * _scrollView.zoomScale - height / 2,
									 width,
									 height);

	
	[_scrollView scrollRectToVisible:centeredRect animated:animated];
}

-(void) setCenterCoordinate:(CLLocationCoordinate2D) coordinate
{
	[self setCenterCoordinate:coordinate animated:NO];
}

-(CLLocationCoordinate2D) centerCoordinate
{
	CGPoint point;
	point.x = _scrollView.contentOffset.x / _scrollView.zoomScale + (_scrollView.frame.size.width / 2) / _scrollView.zoomScale;
	point.y = _scrollView.contentOffset.y / _scrollView.zoomScale + (_scrollView.frame.size.height / 2) / _scrollView.zoomScale;
	
	CLLocationCoordinate2D coordinate = [self coordinateForScreenPoint:point];
	
	return coordinate;
}


-(MKCoordinateRegion) region
{
	MKCoordinateRegion region;
	
	region.center = self.centerCoordinate;

	MKCoordinateSpan span;

	CGPoint point = CGPointMake(_scrollView.contentOffset.x / _scrollView.zoomScale,
								  _scrollView.contentOffset.y / _scrollView.zoomScale);
	
	CLLocationCoordinate2D nw = [self coordinateForScreenPoint:point];
	
	span.latitudeDelta = fabs((nw.latitude - region.center.latitude) * 2);
	span.longitudeDelta = fabs((nw.longitude - region.center.longitude) * 2);
	
	region.span = span;
	
	return region;

}


-(void) setRegion:(MKCoordinateRegion) region
{
	// center it on the region
	//self.centerCoordinate = region.center;
	
	// determine number of pixels from corner to corner
	CLLocationCoordinate2D nw;
	nw.latitude = region.center.latitude + region.span.latitudeDelta / 2;
	nw.longitude = region.center.longitude - region.span.longitudeDelta / 2;
	
	CLLocationCoordinate2D se;
	se.latitude = region.center.latitude - region.span.latitudeDelta / 2;
	se.longitude = region.center.longitude + region.span.longitudeDelta / 2;
	
	CGPoint nwPoint = [self unscaledScreenPointForCoordinate:nw];
	CGPoint sePoint = [self unscaledScreenPointForCoordinate:se];
	
	float horizontal = sePoint.x - nwPoint.x;
	float vertical   = sePoint.y - nwPoint.y;
	
	CGFloat hScale = _scrollView.frame.size.width / horizontal;
	CGFloat vScale = _scrollView.frame.size.height / vertical;
	
	
	_scrollView.zoomScale = (hScale < vScale) ? hScale : vScale;

	self.centerCoordinate = region.center;
	
	// tell the delegate the region changed. 
	if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
		[self.delegate mapViewRegionDidChange:self];
	}
	
	// remove all the preloaded layers to prevent tiles from blocking the correct 
	// rendered layer on this region's level. 
	NSArray* keys = [_preloadedLayers allKeys];
	for (NSString* key in keys)
	{
		UIView* view = [_preloadedLayers objectForKey:key];
		[view.layer removeFromSuperlayer];
		[_preloadedLayers removeObjectForKey:key];
	}
	
}

#pragma mark MapTileDelegate
-(void) tileReceived:(UIImage*)tileImage forLevel:(int)level row:(int)row col:(int)col
{
	//[_tiledLayer setNeedsDisplay];
	
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	if (nil == _userLocationAnnotation) {
		_userLocationAnnotation = [[MITMapUserLocation alloc] init];
	}
	
	[_userLocationAnnotation updateToCoordinate:newLocation.coordinate];
	
	[self updateLocationIcon:YES];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updateLocationIcon:NO];
	[self positionAnnotationViews];
	//[self positionCurrentCallout];

	[_routeView setNeedsDisplay];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	self.stayCenteredOnUserLocation = NO;

	if ([self.delegate respondsToSelector:@selector(mapViewRegionWillChange:)]) {
		[self.delegate mapViewRegionWillChange:self];
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _mapContentView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	self.stayCenteredOnUserLocation = NO;
	
	// tell the delegate the region changed. 
	if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
		[self.delegate mapViewRegionDidChange:self];
	}
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) 
	{		
		// tell the delegate the region changed. 
		if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
			[self.delegate mapViewRegionDidChange:self];
		}
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{	
	// tell the delegate the region changed. 
	if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
		[self.delegate mapViewRegionDidChange:self];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{	
	// tell the delegate the region changed. 
	if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
		[self.delegate mapViewRegionDidChange:self];
	}
}

#pragma mark Annotations
-(NSArray*) annotations
{
	return [NSArray arrayWithArray:_annotations];
}

-(NSArray*) routes
{
	return [NSArray arrayWithArray:_routes];
}

-(void) positionAnnotationView:(MITMapAnnotationView*)annotationView
{
	// determine pixel coordinates for our location relative to the full view of our map
	CGPoint mapPoint = [self screenPointForCoordinate:annotationView.annotation.coordinate];
	//annotationView.layer.position = mapPoint;
	
	CGFloat y = mapPoint.y - (int)round(annotationView.frame.size.height);
	if (annotationView.centeredVertically) {
		y += (int)round(annotationView.frame.size.height / 2);
	}
	
	annotationView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2),
										y,
									  annotationView.frame.size.width,
									  annotationView.frame.size.height);
	
	if (_currentCallout.annotation == annotationView.annotation) {
		[self positionCurrentCallout];
	}
}

-(void) positionCurrentCallout
{
	if(nil == _currentCallout)
		return;
	
	//CGPoint annotationPoint = [self unscaledScreenPointForCoordinate:_currentCallout.annotation.coordinate];
	MITMapAnnotationView* annotationView = [self viewForAnnotation:_currentCallout.annotation];
	
	//CGFloat zoomScale = _scrollView.zoomScale;
	/*
	_currentCallout.frame = CGRectMake((int)round(annotationPoint.x * zoomScale -  _scrollView.contentOffset.x - _currentCallout.frame.size.width / 2),
									   (int)round(annotationPoint.y * zoomScale - _scrollView.contentOffset.y - annotationView.frame.size.height * annotationView.layer.anchorPoint.y - _currentCallout.frame.size.height),
									   _currentCallout.frame.size.width, _currentCallout.frame.size.height);
	*/
	_currentCallout.frame = CGRectMake((int)round(annotationView.frame.origin.x + annotationView.frame.size.width / 2 - _currentCallout.frame.size.width / 2),
									   (int)(annotationView.frame.origin.y - _currentCallout.frame.size.height),
									   _currentCallout.frame.size.width, _currentCallout.frame.size.height);
}

-(void) hideCallout
{
	if (nil == _currentCallout) 
		return;
	
	[_currentCallout removeFromSuperview];
	[_currentCallout release];
	_currentCallout = nil;
}

-(void) refreshCallout
{
	if(nil == _currentCallout)
		return;
	
	id<MKAnnotation> annotation = _currentCallout.annotation;
	
	[self selectAnnotation:annotation animated:NO withRecenter:NO];
}
-(void) positionAnnotationViews
{

	for (MITMapAnnotationView* annotationView in _annotationViews)
	{
		[self positionAnnotationView:annotationView];
	}
}

- (void)addAnnotation:(id <MKAnnotation>)annotation
{
	if(nil == _annotations)
	{
		_annotations = [[NSMutableArray alloc] initWithObjects:annotation, nil];
	}
	else 
	{
		[_annotations addObject:annotation];
	}
	
	// add the view for this annotation
	if (nil == _annotationViews) 
	{
		_annotationViews = [[NSMutableArray alloc] init];
	}
	
	MITMapAnnotationView* annotationView = [self.delegate mapView:self viewForAnnotation:annotation];
	
	// if it was null, give them a default pin annotation
	if(nil == annotationView)
	{
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation] autorelease];
		UIImage* pin = [UIImage imageNamed:@"map_pin_complete.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		annotationView.frame = imageView.frame;
		[annotationView addSubview:imageView];
		annotationView.canShowCallout = YES;
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	
	if(nil != annotationView)
	{
		annotationView.mapView = self;
		
		// we need to insert the annotation view at the right spot. Annotations views should run from north most to south most
		BOOL added = NO;
		for (int idx = 0; idx < _annotationViews.count; idx++) {
			MITMapAnnotationView* previousAnnnotationView = [_annotationViews objectAtIndex:idx];
			
			if (annotation.coordinate.latitude > previousAnnnotationView.annotation.coordinate.latitude) {
				added = YES;
				CALayer* layer = [annotationView layer];
				
				[_annotationViews insertObject:annotationView atIndex:idx];
				
				
				[self.layer insertSublayer:layer below:previousAnnnotationView.layer];
				//[annotationView setNeedsDisplay];
				
				//[self insertSubview:annotationView belowSubview:previousAnnnotationView];
				
				break;
			}
		}
		
		if(!added)
		{
			// just add them at the end. 
			[_annotationViews addObject:annotationView];
			//[self addSubview:annotationView];
			[self.layer addSublayer:annotationView.layer];
		}
		
		[self positionAnnotationView:annotationView];
	}
	
}

- (void)addAnnotations:(NSArray *)annotations
{
	for (id<MKAnnotation> annotation in annotations)
	{
		[self addAnnotation:annotation];
	}
}

- (void)removeAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = [self viewForAnnotation:annotation];
	
	if(nil != annotationView)
	{
		[annotationView.layer removeFromSuperlayer];
		//[annotationView removeFromSuperview];
	
		[_annotationViews removeObject:annotationView];
	
		if (_currentCallout.annotation == annotation) {
			[_currentCallout removeFromSuperview];
			_currentCallout = nil;
		}
	
	}
	[_annotations removeObject:annotation];
	
}

- (void)removeAnnotations:(NSArray *)annotations
{
	for(id<MKAnnotation> annotation in annotations)
	{
		[self removeAnnotation:annotation];
	}
}


- (void)addRoute:(id<MITMapRoute>) route
{
	if (nil == _routes) {
		_routes = [[NSMutableArray alloc] initWithCapacity:1];
	}
	
	[_routes addObject:route];
	
	// add any annotations associated with this route
	[self addAnnotations:route.annotations];
	
	if (nil == _routeView) {
		// add the layer for displaying routes. 
		_routeView = [[RouteView alloc] initWithFrame:_scrollView.frame];
		_routeView.map = self;
		_routeView.userInteractionEnabled = NO;
		//_routeView.backgroundColor = [UIColor clearColor];
		_routeView.opaque = NO;
		[self insertSubview:_routeView aboveSubview:_scrollView];
	}
	
}

- (void)removeRoute:(id<MITMapRoute>) route
{
	[_routes removeObject:route];
	
	[self removeAnnotations:route.annotations];
	
	if (_routes.count <= 0) {
		[_routeView removeFromSuperview];
		[_routeView release];
		_routeView = nil;
	}
}

- (void)annotationTapped:(NSNotification*)notif
{
	MITMapAnnotationView* annotationView = [notif object];
	
	if (annotationView.mapView == self && annotationView.canShowCallout) 
	{
		[self selectAnnotation:annotationView.annotation];
	}

}

- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter
{
	if([annotation isKindOfClass:[MITMapSearchResultAnnotation class]])
	{
		MITMapSearchResultAnnotation* searchAnnotation = (MITMapSearchResultAnnotation*)annotation;
		// if the annotation is not fully loaded, try to load it
		if (!searchAnnotation.dataPopulated) 
		{
			NSString* searchURL = [NSString stringWithFormat:[MITMapSearchResultAnnotation urlSearchString], [searchAnnotation.bldgnum stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			NSLog(@"searchURL = %@", searchURL);
			PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
			postData.userData = [NSDictionary dictionaryWithObject:annotation forKey:@"annotation"];
			postData.api = @"search";
			[postData postDataInDictionary:nil toURL:[NSURL URLWithString:searchURL]];
		}
	}
	MITMapAnnotationCalloutView* callout = [[MITMapAnnotationCalloutView alloc] initWithAnnotation:annotation andMapView:self];
	[_currentCallout removeFromSuperview];
	[_currentCallout release];
	
	_currentCallout = callout;
	
	[self addSubview:callout];
	[self positionCurrentCallout];
	
	if (recenter) 
	{
		
		CGPoint point = [self unscaledScreenPointForCoordinate:_currentCallout.annotation.coordinate];
		point.y -= 50 / _scrollView.zoomScale;
		CLLocationCoordinate2D coordinate = [self coordinateForScreenPoint:point];
		
		[self setCenterCoordinate:coordinate animated:animated];

	}

}

- (void)selectAnnotation:(id<MKAnnotation>) annotation
{
	[self selectAnnotation:annotation animated:YES withRecenter:YES];
}

- (MITMapAnnotationView *)viewForAnnotation:(id <MKAnnotation>)annotation
{
	for (MITMapAnnotationView* annotationView in _annotationViews)
	{
		if (annotationView.annotation == annotation) {
			return annotationView;
		}
		
	}
	
	return nil;
	
}

#pragma mark PostDataDelegate
// data was received from the post data request. 
-(void) postData:(PostData*)postData receivedData:(NSData*) data
{
	if ([postData.api isEqualToString:@"search"]) 
	{
		MITMapSearchResultAnnotation* oldAnnotation = [postData.userData objectForKey:@"annotation"];
		
		NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSArray* results = [string JSONValue];
		
		if (results.count > 0) 
		{
			MITMapSearchResultAnnotation* newAnnotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:[results objectAtIndex:0]] autorelease];
			
			BOOL isViewingAnnotation = (_currentCallout.annotation == oldAnnotation);
			
			[self removeAnnotation:oldAnnotation];
			[self addAnnotation:newAnnotation];
			
			if (isViewingAnnotation) {
				[self selectAnnotation:newAnnotation animated:NO withRecenter:NO];
			}
			
			/*
			// if the user was looking at the old annotation, update its callout view. 
			if (_currentCallout.annotation == oldAnnotation) 
			{
				[_currentCallout setAnnotation:newAnnotation];
				[_currentCallout setNeedsDisplay];
				[self positionCurrentCallout];
			}
			 */
			
		}
	}
}

// there was an error connecting to the specified URL. 
-(void) postData:(PostData*)postData error:(NSString*)error
{
	
	
}

@end
