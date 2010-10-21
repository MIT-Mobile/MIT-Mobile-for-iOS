
#import "MITMapView.h"
#import "MapLevel.h"
#import "MITMapUserLocation.h"
#import "MITMapSearchResultAnnotation.h"
#import "NSString+SBJSON.h"
#import "RouteView.h"

#define kTileSize 256
#define LogRect(rect, message) NSLog(@"%@ rect: %f %f %f %f", message,  rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)

#define kRadiusOfEarthInMeters	      6378100.0
#define kMinAccuracyToBounceAnimation	  110.0
#define kMaxPixelRadiusToMinimize		   25.0
#define kPinDropTimerFrequency				0.05
#define kPinDropAnimationDuration			1.6

@interface MITMapView(Private) 

-(void) createSubviews;

-(void) positionAnnotationViews;

-(void) positionCurrentCallout;

-(void) onscreenTilesLevel:(int*)level minRow:(int*)minRow minCol:(int*)minCol maxRow:(int*)maxRow maxCol:(int*)maxCol;

-(void) removePreloadedTile:(NSString*)index;

// get the tiles that should be onscreen. Tiles are returned as dictionaries with level, row and col values. 
-(void) onscreenTilesLevel:(int*)level row:(int*)row col:(int*)col;

-(void) animateCircleLayerForLocations:(NSArray*)locationsArray;
-(void) bounceAccuracyAnimationForLocation:(CLLocation*)location;
-(void) animateToBounceForLocation:(CLLocation*)location;
-(void) animateToAccuracyOfLocation:(CLLocation*)location;
-(CABasicAnimation*) animationToRadiusPathForLocation:(CLLocation*)location;
-(CGMutablePathRef) newRadiusPathFromLocation:(CLLocation*)location;
-(void) addRadiationAnimationForLocation:(CLLocation*)location;
-(void) removeRadiationAnimation;
-(void) handleLayerAnimationDuringScroll;
-(void) locationDeniedMessage;

@end

@implementation MITMapView
@synthesize mapLevels = _mapLevels;
@synthesize showsUserLocation = _showsUserLocation;
@synthesize stayCenteredOnUserLocation = _stayCenteredOnUserLocation;
@synthesize delegate = _mapDelegate;
@synthesize shouldNotDropPins = _shouldNotDropPins;
@dynamic currentAnnotation;


- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	self.mapLevels = nil;
	
	[_mapContentView release];
	
	_scrollView.delegate = nil;	
	[_scrollView release];
	
	[_tiledLayer release];
	
	[_locationView release];
	
	[_lastLocation release];
	_lastLocation = nil;
	
	[_locationManager release];
	
	[_userLocationAnnotation release];
	
	[_annotationViews release];
	
	[_annotationShadowViews release];

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

-(void) cacheReset:(NSNotification*) notification
{
	[_tiledLayer setNeedsDisplay];
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cacheReset:) name:MapCacheReset object:nil];
	
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
	
	NSDictionary* initialLocationInfo = [mapInfo objectForKey:@"InitialLocation"];
	
	_initialLocation.latitude = [[initialLocationInfo objectForKey:@"Latitude"] doubleValue];
	_initialLocation.longitude = [[initialLocationInfo objectForKey:@"Longitude"] doubleValue];
	
    _initialZoom = [[initialLocationInfo objectForKey:@"Zoom"] doubleValue];
	
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
    //_scrollView.scrollsToTop = NO;
	_scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	[_scrollView addSubview:_mapContentView];


	[self addSubview:_scrollView];
	
	// move to the initial point
	_scrollView.zoomScale = _initialZoom;
	[self setCenterCoordinate:_initialLocation animated:NO];
	
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

/*
 *	This calculates the correct radius in pixels for the location based on its coordinate and horizontal accuracy.
 */
-(CGFloat) pixelRadiusForAccuracyOfLocation:(CLLocation*)location
{
	if (location) {
		// get the screen point for the coordinate
		CGPoint firstScreenPoint = [self screenPointForCoordinate:location.coordinate];
		
		// calculate where the other coordinate is -- use due south to make calculations easy
		double distanceInRadians = location.horizontalAccuracy / kRadiusOfEarthInMeters;
		double oldLatitudeInRadians = location.coordinate.latitude * M_PI / 180;
		// new latitude is lat1 - distance (all in radians)
		double newLatitudeInRadians = oldLatitudeInRadians + distanceInRadians;
		double newLatitudeInDegrees = newLatitudeInRadians * 180 / M_PI;
		
		CLLocationCoordinate2D secondCoordinate;
		secondCoordinate.latitude = newLatitudeInDegrees;
		secondCoordinate.longitude = location.coordinate.longitude;
		
		// get the screen point for the other coordinate
		CGPoint secondScreenPoint = [self screenPointForCoordinate:secondCoordinate];
		
		// subtract
		CGFloat pixelRadius = firstScreenPoint.y-secondScreenPoint.y;
		
		return pixelRadius;
	} else {
		return 300;
	}

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
		
		_displayedLocationDenied = NO;
		[_locationManager setDelegate:self];
		[_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
		[_locationManager setDistanceFilter:kCLDistanceFilterNone];
		[_locationManager startUpdatingLocation];
		
		if (nil == _locationView) 
		{
			// create and add the location layer
			_locationLayer = [CALayer layer];
			_locationLayer.frame = CGRectMake(-200, -200, self.frame.size.width, self.frame.size.height);
			_locationLayer.anchorPoint = CGPointMake(0.5, 0.5);

			[self.layer addSublayer:_locationLayer];
			
			// create the location view and move it offscreen until a location is found
			_locationView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_location_complete.png"]]; 
			_locationView.layer.anchorPoint = CGPointMake(0.5, 0.5);
			_locationView.frame = CGRectMake(_locationLayer.frame.size.width/2-_locationView.frame.size.width/2, 
											 _locationLayer.frame.size.height/2-_locationView.frame.size.height/2, 
											 _locationView.frame.size.width, 
											 _locationView.frame.size.height); 
			
//			_locationView.layer.bounds = CGRectMake(0, 0, 320, 416);
//			[self.layer addSublayer:_locationView.layer];
			[_locationLayer addSublayer:_locationView.layer];

			//[self addSubview:_locationView];				 
		}
	}
	else {
		[_locationView.layer removeFromSuperlayer];
		[_locationView release];
		_locationView = nil;
		//[_locationView removeFromSuperview];
		[_locationAccuracyCircleLayer removeFromSuperlayer];
		[_locationAccuracyCircleLayer release];
		_locationAccuracyCircleLayer = nil;
		[_radiationLayer1 removeFromSuperlayer];
		[_radiationLayer1 release];
		_radiationLayer1 = nil;
		[_radiationLayer2 removeFromSuperlayer];
		[_radiationLayer2 release];
		_radiationLayer2 = nil;
		[_locationLayer removeFromSuperlayer];
		[_locationLayer release];
		_locationLayer = nil;
		
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
	
	_locationLayer.position = CGPointMake(mapPoint.x * zoomScale - _scrollView.contentOffset.x,
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
	if (nil != _locationManager && nil != _lastLocation) {
		
		[userLocation updateToCoordinate:_lastLocation.coordinate];	
				
	}
	
	return userLocation;
}


-(void) setStayCenteredOnUserLocation:(BOOL)centerOnUser
{
	
	_stayCenteredOnUserLocation = centerOnUser;
	
	if(_locationDenied && _stayCenteredOnUserLocation)
	{
		if([_mapDelegate respondsToSelector:@selector(locateUserFailed)])
			[_mapDelegate locateUserFailed];
	
		_stayCenteredOnUserLocation = NO;
		_displayedLocationDenied = NO;
		[self locationDeniedMessage];
		
		return;
	}
	
	if(_stayCenteredOnUserLocation && _userLocationAnnotation)
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


- (NSString *)serializeCurrentRegion
{
	MKCoordinateRegion region = self.region;
	return [NSString stringWithFormat:@"%.8f:%.8f:%.8f:%.8f", region.center.latitude, region.center.longitude, region.span.latitudeDelta, region.span.longitudeDelta];
}

- (void)unserializeRegion:(NSString *)regionString
{
	NSArray *components = [regionString componentsSeparatedByString:@":"];
	if ([components count] == 4) {
		CLLocationCoordinate2D theCenter = { latitude: [[components objectAtIndex:0] doubleValue], longitude: [[components objectAtIndex:1] doubleValue] };
		MKCoordinateSpan theSpan = MKCoordinateSpanMake([[components objectAtIndex:2] doubleValue], [[components objectAtIndex:3] doubleValue]);
		MKCoordinateRegion theRegion = MKCoordinateRegionMake(theCenter, theSpan);
		self.region = theRegion;
	}
}

-(void) locationDeniedMessage
{
	if(!_displayedLocationDenied)
	{
		_displayedLocationDenied = YES;
		
		UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Required", nil)
													 message:NSLocalizedString(@"Please restart this application, and when prompted, select \"OK\" to allow the application to locate you.", nil) 
													delegate:nil
										   cancelButtonTitle:NSLocalizedString(@"OK", nil)
										   otherButtonTitles:nil] autorelease];
		[alert show];
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
	
	NSArray* locationsArray = [NSArray arrayWithObjects:newLocation, oldLocation, nil];
	[self performSelectorOnMainThread:@selector(animateCircleLayerForLocations:) withObject:locationsArray waitUntilDone:NO];
	
	[_lastLocation release];
	_lastLocation = nil;
	_lastLocation = [newLocation retain];
	[self updateLocationIcon:YES];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	if (error.code == kCLErrorDenied) 
	{
		if([_mapDelegate respondsToSelector:@selector(locateUserFailed)])
			[_mapDelegate locateUserFailed];
		
		if(_receivedFirstLocationDenied && _stayCenteredOnUserLocation)
			[self locationDeniedMessage];
		else {
			_receivedFirstLocationDenied = YES;
		}
		
		_stayCenteredOnUserLocation = NO;

	}
	
	_locationDenied = YES;
}

#pragma mark Circle Animation
/*
 *	This method adds three layers to the location layer: an accuracy circle and two radiating circles.
 *	Different animations are called on these layers based on the accuracy of the new and previous points.
 */
-(void) animateCircleLayerForLocations:(NSArray*)locationsArray
{
	CLLocation* newLocation = [locationsArray objectAtIndex:0];
	CLLocation* oldLocation = nil;
	if (locationsArray.count > 1) {
		oldLocation = [locationsArray objectAtIndex:1];
	}
	
//	NSLog(@"new point: %@", newLocation);
	
	if (!_locationAccuracyCircleLayer) 
	{
		CGPoint center = _locationView.center;
		
		_locationAccuracyCircleLayer = [CAShapeLayer layer];
		_locationAccuracyCircleLayer.fillColor = [UIColor colorWithRed:0 green:0.5 blue:0.9 alpha:0.1].CGColor;
		_locationAccuracyCircleLayer.strokeColor = [UIColor colorWithRed:0 green:0.5 blue:0.9 alpha:0.8].CGColor;
		_locationAccuracyCircleLayer.lineWidth = 2.0;
		_locationAccuracyCircleLayer.fillRule = kCAFillRuleNonZero;
		
		[_locationLayer insertSublayer:_locationAccuracyCircleLayer below:_locationView.layer];
		
		CGMutablePathRef hugePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(hugePath, nil, CGRectMake(center.x-300, center.y-300, 600, 600));
		_locationAccuracyCircleLayer.path = hugePath;
		
		_radiationLayer1 = [CAShapeLayer layer];
		_radiationLayer1.fillColor = [UIColor clearColor].CGColor;
		_radiationLayer1.strokeColor = [UIColor colorWithRed:0 green:0.5 blue:0.9 alpha:0.8].CGColor;
		
		_radiationLayer2 = [CAShapeLayer layer];
		_radiationLayer2.fillColor = [UIColor clearColor].CGColor;
		_radiationLayer2.strokeColor = [UIColor colorWithRed:0 green:0.5 blue:0.9 alpha:0.8].CGColor;
		
		[_locationLayer insertSublayer:_radiationLayer1 below:_locationAccuracyCircleLayer];
		[_locationLayer insertSublayer:_radiationLayer2 below:_locationAccuracyCircleLayer];
		
		CGMutablePathRef tinyPath = CGPathCreateMutable();
		CGPathAddEllipseInRect(tinyPath, nil, CGRectMake(center.x-1, center.y-1, 2, 2));
		
		CGMutablePathRef tinyOutsidePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(tinyOutsidePath, nil, CGRectMake(center.x-3, center.y-3, 6, 6));
		
		_radiationLayer1.path = tinyPath;
		_radiationLayer2.path = tinyOutsidePath;
		
		[self animateToBounceForLocation:newLocation];
		[self bounceAccuracyAnimationForLocation:newLocation]; 
		if (newLocation.horizontalAccuracy) {
			[self animateToAccuracyOfLocation:newLocation];
		}
		CGPathRelease(hugePath);
		CGPathRelease(tinyPath);
		CGPathRelease(tinyOutsidePath);
	} else {
		if (newLocation.horizontalAccuracy > kMinAccuracyToBounceAnimation) {
			[self removeRadiationAnimation];
			// if the new accuracy is too big, we want to show the bounce animation.
			if (oldLocation != nil && oldLocation.horizontalAccuracy < kMinAccuracyToBounceAnimation) {
				// if they are changing from good accuracy to bad/bouncy, we need to get them to that bounce size before bouncing.
				[self animateToBounceForLocation:newLocation];
			}
			if (!_animationIsBouncing) {
				[self bounceAccuracyAnimationForLocation:newLocation];
			}
		} else {
			if (oldLocation != nil && fabs(newLocation.horizontalAccuracy - oldLocation.horizontalAccuracy) > 3) {
				_animationIsRadiating = NO;
			}
			[self animateToAccuracyOfLocation:newLocation];
			[self addRadiationAnimationForLocation:newLocation];
		}
	}
}

/*
 *	This animates the accuracy circle to the appropriate radius to begin bounce animation.  
 *	It should be called if accuracy changes from good to poor.
 */
-(void) animateToBounceForLocation:(CLLocation*)location 
{
	CABasicAnimation* animation = [self animationToRadiusPathForLocation:location];
	
	[_locationAccuracyCircleLayer addAnimation:animation forKey:@"animateToBounce"];
}

/*	
 *	This animates the accuracy circle endlessly between two paths when accuracy is poor.
 */
-(void) bounceAccuracyAnimationForLocation:(CLLocation*)location
{

	_animationIsBouncing = YES;
	[self removeRadiationAnimation];
	CGFloat pixelRadius = [self pixelRadiusForAccuracyOfLocation:location];
	
	CGPoint center = _locationView.center;
	
	// create the three shapes we need
	
	CGMutablePathRef radiusPath = CGPathCreateMutable();
	CGPathAddEllipseInRect(radiusPath, nil, CGRectMake(center.x-(pixelRadius), center.y-(pixelRadius), (pixelRadius)*2, (pixelRadius)*2));
	
	CGMutablePathRef wobblePath = CGPathCreateMutable();
	CGPathAddEllipseInRect(wobblePath, nil, CGRectMake(center.x-(pixelRadius*0.9), center.y-(pixelRadius*0.9), (pixelRadius*0.9)*2, (pixelRadius*0.9)*2));
	
	//create the animation
	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
	animation.duration = 0.6;
	animation.repeatCount = 1e100f;
	animation.autoreverses = YES;
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.fromValue = (id)radiusPath;
	animation.toValue = (id)wobblePath;
	
	[_locationAccuracyCircleLayer addAnimation:animation forKey:@"animationPath"];
	
	CGPathRelease(radiusPath);
	CGPathRelease(wobblePath);
}

/*
 *	This animates the accuracy circle from its bounce radius to the accuracy radius.
 */
-(void) animateToAccuracyOfLocation:(CLLocation*)location
{
	_animationIsBouncing = NO;
		
	CABasicAnimation* animation = [self animationToRadiusPathForLocation:location];
	[_locationAccuracyCircleLayer addAnimation:animation forKey:@"animationPath"];
	CGMutablePathRef radiusPath = [self newRadiusPathFromLocation:(CLLocation*)location];
	_locationAccuracyCircleLayer.path = radiusPath;
	CGPathRelease(radiusPath);
}

/*
 *	This is a convenience method called in the above methods.  It returns the animation from the accuracy
 *	circle's present (radius) path to the path (radius) for its current accuracy. 
 */
-(CABasicAnimation*) animationToRadiusPathForLocation:(CLLocation*)location
{	
	CAShapeLayer* presentationLayer = (CAShapeLayer*)[_locationAccuracyCircleLayer presentationLayer];
	CGMutablePathRef presentPath = CGPathCreateMutableCopy([presentationLayer path]);
	
	if (!presentPath) {
		CGPoint center = _locationView.center;
		presentPath = CGPathCreateMutable();
		CGPathAddEllipseInRect(presentPath, nil, CGRectMake(center.x-300, center.y-300, 600, 600));
	}
	
	CGMutablePathRef radiusPath = [self newRadiusPathFromLocation:(CLLocation*)location];
	
	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
	animation.fromValue = (id)presentPath;
	animation.toValue = (id)radiusPath;
	CGPathRelease(presentPath);
	CGPathRelease(radiusPath);
	return animation;
}

/*
 *	This returns the correct path given the location of the GPS point.
 */
-(CGMutablePathRef) newRadiusPathFromLocation:(CLLocation*)location
{
	CGFloat pixelRadius = [self pixelRadiusForAccuracyOfLocation:location];
	
	// we want the circle to disapear if it's too close to the dot
	pixelRadius = (pixelRadius < kMaxPixelRadiusToMinimize) ? 0 : pixelRadius;
	if (pixelRadius < kMaxPixelRadiusToMinimize)
		[self removeRadiationAnimation];
	
	CGPoint center = _locationView.center;
	
	CGMutablePathRef radiusPath = CGPathCreateMutable();
	CGPathAddEllipseInRect(radiusPath, nil, CGRectMake(center.x-pixelRadius, center.y-pixelRadius, pixelRadius*2, pixelRadius*2));

	return radiusPath;
}

/*
 *	This animates the two radiation circle layers.  
 *	First it calculates the radius of the radiation circles so they are the same radius as the present accuracy circle.
 *	Then it animates both circles path and opacity.
 */
-(void) addRadiationAnimationForLocation:(CLLocation*)location
{
	if (!_animationIsRadiating) 
	{
		_animationIsRadiating = YES;
		CGPoint center = _locationView.center;
		CGMutablePathRef tinyPath = CGPathCreateMutable();
		CGPathAddEllipseInRect(tinyPath, nil, CGRectMake(center.x-1, center.y-1, 2, 2));
		
		CGMutablePathRef tinyOutsidePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(tinyOutsidePath, nil, CGRectMake(center.x-3, center.y-3, 6, 6));
		
		CGFloat pixelRadius = [self pixelRadiusForAccuracyOfLocation:location];
		pixelRadius = (pixelRadius < kMaxPixelRadiusToMinimize) ? 0 : pixelRadius;
		
		CGMutablePathRef radiusPath = CGPathCreateMutable();
		CGPathAddEllipseInRect(radiusPath, nil, CGRectMake(center.x-pixelRadius, center.y-pixelRadius, pixelRadius*2, pixelRadius*2));
		
		CGMutablePathRef radiusOutsidePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(radiusOutsidePath, nil, CGRectMake(center.x-pixelRadius-4, center.y-pixelRadius-4, (pixelRadius+4)*2, (pixelRadius+4)*2));
		
		CABasicAnimation* pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
		pathAnimation.fromValue = (id)tinyPath;
		pathAnimation.toValue = (id)radiusPath;
		
		CABasicAnimation* opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
		opacityAnimation.toValue = [NSNumber numberWithFloat:0.0];
		
		CAAnimationGroup* animationGroup = [CAAnimationGroup animation];
		animationGroup.animations = [NSArray arrayWithObjects:pathAnimation, opacityAnimation, nil];
		animationGroup.duration = 2;
		animationGroup.autoreverses = NO;
		animationGroup.repeatCount = 1e100f;
		
		CABasicAnimation* outsidePathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
		outsidePathAnimation.fromValue = (id)tinyOutsidePath;
		outsidePathAnimation.toValue = (id)radiusOutsidePath;
		
		CAAnimationGroup* animationGroupOutside = [CAAnimationGroup animation];
		animationGroupOutside.animations = [NSArray arrayWithObjects:outsidePathAnimation, opacityAnimation, nil];
		animationGroupOutside.duration = 2;
		animationGroupOutside.autoreverses = NO;
		animationGroupOutside.repeatCount = 1e100f;
		
		[_radiationLayer1 addAnimation:animationGroup forKey:@"group"];
		[_radiationLayer2 addAnimation:animationGroupOutside forKey:@"group"];
		
		CGPathRelease(tinyPath);
		CGPathRelease(tinyOutsidePath);
		CGPathRelease(radiusPath);
		CGPathRelease(radiusOutsidePath);
	}
}

/*
 *	This removes all animations from the radiation layers.  It should be called whenever accuracy becomes poor.
 */
-(void) removeRadiationAnimation
{
	[_radiationLayer1 removeAllAnimations];
	[_radiationLayer2 removeAllAnimations];
	_animationIsRadiating = NO;
}

/*
 *	When the user scrolls, we update the sizes of our circle layers appropriately.
 */
-(void) handleLayerAnimationDuringScroll
{
	CGFloat pixelRadius = [self pixelRadiusForAccuracyOfLocation:_lastLocation];
	if (!_animationIsBouncing && _lastLocation) {
		if (pixelRadius >= kMaxPixelRadiusToMinimize) {
			if (_locationCircleIsMinimized) {
				// animate out to accuracy circle
				[self animateToAccuracyOfLocation:_lastLocation];
				_locationCircleIsMinimized = NO;
				[self addRadiationAnimationForLocation:_lastLocation];
			} else {
				// change layer to new path without animation
				CGMutablePathRef radiusPath = [self newRadiusPathFromLocation:(CLLocation*)_lastLocation];
				_locationAccuracyCircleLayer.path = radiusPath;
				[self addRadiationAnimationForLocation:_lastLocation];
				CGPathRelease(radiusPath);
			}
		} else {
			// we want the circle to animate to disapear if it's too close to the dot
			_locationCircleIsMinimized = YES;
			[self animateToAccuracyOfLocation:_lastLocation];
			[self removeRadiationAnimation];
		}
	} else if (_animationIsBouncing && _lastLocation) {
		if (pixelRadius > kMaxPixelRadiusToMinimize) {
			[self animateToAccuracyOfLocation:_lastLocation];
			[self bounceAccuracyAnimationForLocation:_lastLocation];
		}
	}
}

#pragma mark UIScrollViewDelegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (_scrollView) { // these variables were initialized in the same block
        self.stayCenteredOnUserLocation = NO;
        self.centerCoordinate = _initialLocation;
        _scrollView.zoomScale = _initialZoom;
    }
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updateLocationIcon:NO];
	[self positionAnnotationViews];
	//[self positionCurrentCallout];
	
	[self performSelectorOnMainThread:@selector(handleLayerAnimationDuringScroll) withObject:nil waitUntilDone:NO];

	[_routeView setNeedsDisplay];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	self.stayCenteredOnUserLocation = NO;

	if ([self.delegate respondsToSelector:@selector(mapViewRegionWillChange:)]) {
		[self.delegate mapViewRegionWillChange:self];
	}
	// set the location layer to not animate position
	NSMutableDictionary* noPositionAnimationDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", nil];
	_locationLayer.actions = noPositionAnimationDict;
	[noPositionAnimationDict release];
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
	
	if (!_animationIsBouncing && _lastLocation) {
		// Change the size of the radiation circles
		_animationIsRadiating = NO;
		[self performSelectorOnMainThread:@selector(addRadiationAnimationForLocation:) withObject:_lastLocation waitUntilDone:NO];
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
	// set the layers actions back to the default (so the dot & circle will animate to new position)
	id defaultPositionAction = [CALayer defaultActionForKey:@"position"];
	NSMutableDictionary* defaultPositionAnimationDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultPositionAction, @"position", nil];
	_locationLayer.actions = defaultPositionAnimationDict;
	[defaultPositionAnimationDict release];
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

-(void) positionAnnotationViews
{	
	for (MITMapAnnotationView* annotationView in _annotationViews)
	{
		//		// if any of these annotations have not been placed on the map yet, use the timer to drop them sequentially
		if (annotationView.alreadyOnMap) {
			[self positionAnnotationView:annotationView];
		} else if (!annotationView.hasBeenDropped) {
			if (_pinDropTimer == nil) {
				_pinDropTimer = [[NSTimer scheduledTimerWithTimeInterval:kPinDropTimerFrequency target:self selector:@selector(pinDropTimerFired:) userInfo:nil repeats:YES] retain];
			}
		}
		
	}
}

/*
 *	If the annotationView is already on the map, this positions it appropriately given its location and image size.
 *	If the annotationView is not yet on the map, this calls the animation code on the main thread so pin appears to drop from above with shadow.
 */
-(void) positionAnnotationView:(MITMapAnnotationView*)annotationView
{
	// determine pixel coordinates for our location relative to the full view of our map
	CGPoint mapPoint = [self screenPointForCoordinate:annotationView.annotation.coordinate];
	//annotationView.layer.position = mapPoint;
	
	CGFloat y = mapPoint.y - (int)round(annotationView.frame.size.height);
	if (annotationView.centeredVertically) {
		y += (int)round(annotationView.frame.size.height / 2);
	}
	
	if (annotationView.alreadyOnMap) {
		annotationView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2),
												y,
												annotationView.frame.size.width,
												annotationView.frame.size.height);
	} else {
		[self performSelectorOnMainThread:@selector(animateAnnotationOntoMap:) withObject:annotationView waitUntilDone:NO];
	}
	
	if (_currentCallout.annotation == annotationView.annotation) {
		[self positionCurrentCallout];
	}
}

/*
 *	This creates the keyframe animations for one pin and shadow to drop onto the map.
 */
-(void) animateAnnotationOntoMap:(MITMapAnnotationView*)annotationView
{
	
	CGPoint mapPoint = [self screenPointForCoordinate:annotationView.annotation.coordinate];
	CGFloat y = mapPoint.y - (int)round(annotationView.frame.size.height);
	if (annotationView.centeredVertically) {
		y += (int)round(annotationView.frame.size.height / 2);
	}
	
	// animate pins dropping
	UIImageView* annotationShadowView;
	if (annotationView.shadowView != nil) {
		annotationShadowView = annotationView.shadowView;
		annotationShadowView.alpha = 1.0;
		annotationShadowView.layer.frame = CGRectMake(mapPoint.x-(int)round(annotationView.frame.size.width / 2) + 260, 
													  y-160, 
													  annotationShadowView.frame.size.width, 
													  annotationShadowView.frame.size.height);
	}
	
	annotationView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2), 
											y-480, 
											annotationView.frame.size.width, 
											annotationView.frame.size.height);
	
	CGFloat animationY = mapPoint.y - (int)round(annotationView.frame.size.height/2);
	CAKeyframeAnimation* pinDropAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	pinDropAnimation.duration = kPinDropAnimationDuration;
	CGPoint startingPoint = CGPointMake(mapPoint.x, mapPoint.y-480);
	CGPoint endingPoint = CGPointMake(mapPoint.x, mapPoint.y);
	pinDropAnimation.values = [NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:startingPoint], 
							   [NSValue valueWithCGPoint:endingPoint], 
							   [NSValue valueWithCGPoint:endingPoint], 
							   [NSValue valueWithCGPoint:endingPoint], 
							   nil];
	pinDropAnimation.keyTimes = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
	pinDropAnimation.timingFunctions = [NSMutableArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
										[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
										[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
										nil];
	pinDropAnimation.delegate = self;

	[annotationView.layer addAnimation:pinDropAnimation forKey:@"pinDrop"];
	
	CAKeyframeAnimation* pinSquishAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
	pinSquishAnimation.duration = kPinDropAnimationDuration;
	pinSquishAnimation.values = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
	pinSquishAnimation.keyTimes = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
	pinSquishAnimation.timingFunctions = [NSMutableArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
										[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
										[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
										nil];
	[annotationView.layer addAnimation:pinSquishAnimation forKey:@"squish"];
	
	// set the final values
	annotationView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2),
											y,
											annotationView.frame.size.width,
											annotationView.frame.size.height);
	
	if (annotationView.shadowView != nil) {
		CAKeyframeAnimation* shadowDropAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		shadowDropAnimation.duration = kPinDropAnimationDuration;
		CGPoint shadowStartingPoint = CGPointMake(mapPoint.x+320, animationY-200);
		CGPoint shadowEndingPoint = CGPointMake(mapPoint.x, animationY);
		shadowDropAnimation.values = [NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:shadowStartingPoint], 
									  [NSValue valueWithCGPoint:shadowEndingPoint], 
									  [NSValue valueWithCGPoint:shadowEndingPoint], 
									  [NSValue valueWithCGPoint:shadowEndingPoint], 
									  nil];
		shadowDropAnimation.keyTimes = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
		shadowDropAnimation.timingFunctions = [NSMutableArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
											[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
											nil];
		[annotationShadowView.layer addAnimation:shadowDropAnimation forKey:@"pinDrop"];
		
		CAKeyframeAnimation* shadowOpacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
		shadowOpacityAnimation.duration = kPinDropAnimationDuration;
		shadowOpacityAnimation.values = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:1.0], nil];
		shadowOpacityAnimation.keyTimes = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
		shadowOpacityAnimation.timingFunctions = [NSMutableArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
												  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
											   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
											   nil];
		[annotationShadowView.layer addAnimation:shadowOpacityAnimation forKey:@"opacity"];
		
		CAKeyframeAnimation* shadowSquishAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
		shadowSquishAnimation.duration = kPinDropAnimationDuration;
		shadowSquishAnimation.values = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
		shadowSquishAnimation.keyTimes = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
		pinSquishAnimation.timingFunctions = [NSMutableArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
											  nil];
		[annotationShadowView.layer addAnimation:shadowSquishAnimation forKey:@"squish"];
		
		annotationShadowView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2),
													  y,
													  annotationView.frame.size.width,
													  annotationView.frame.size.height);
		
		// set the final values
		annotationShadowView.layer.frame = CGRectMake(mapPoint.x - (int)round(annotationView.frame.size.width / 2),
													  y,
													  annotationView.frame.size.width,
													  annotationView.frame.size.height);
	}
}

/*
 *	After each pin drop animation has finished, we mark that annotation view as alreadyOnMap and replace the two layers (pin and shadow)
 *	with one UIImageView that has the combined image.
 */
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	UIImageView* pinWithShadowImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_pin_complete.png"]] autorelease];
	// switch image on annotationView layer and remove shadow layer
	for (MITMapAnnotationView* annotationView in _annotationViews) {
		if (!annotationView.hasBeenDropped || annotationView.alreadyOnMap) {
			continue;
		} else {
			annotationView.alreadyOnMap = YES;
			[annotationView addSubview:pinWithShadowImageView];

			UIImageView* shadowView = annotationView.shadowView;

			[shadowView.layer removeFromSuperlayer];
			
			annotationView.shadowView = nil;
			[_annotationShadowViews removeObject:shadowView];
						
			break;
		}
	}

	if (_annotationShadowViews.count == 0) {
		[_annotationShadowViews release];
		_annotationShadowViews = nil;
	}
	
	// if there is only one annotation on the map, select it
	if (_annotationViews.count == 1) {
		MITMapAnnotationView* annotationView = [_annotationViews objectAtIndex:0];
		[self selectAnnotation:annotationView.annotation];
	}
}

-(void) positionCurrentCallout
{
	if(nil == _currentCallout)
		return;
	
	MITMapAnnotationView* annotationView = [self viewForAnnotation:_currentCallout.annotation];
	
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
	
	if ([_mapDelegate respondsToSelector:@selector(annotationCalloutDidDisappear)]) {
		[_mapDelegate annotationCalloutDidDisappear];
	}
}

-(void) refreshCallout
{
	if(nil == _currentCallout)
		return;
	
	id<MKAnnotation> annotation = _currentCallout.annotation;
	
	[self selectAnnotation:annotation animated:NO withRecenter:NO];
}

/*
 *	If there are pins to animate onto the map, this timer is created.  Each time it is fired, we drop one pin onto the map.
 */
-(void) pinDropTimerFired:(NSTimer*)timer
{
	BOOL allPinsDropped = YES;
	for (MITMapAnnotationView* annotationView in _annotationViews)
	{
		if (!annotationView.hasBeenDropped) {
			annotationView.hasBeenDropped = YES;
			[self positionAnnotationView:annotationView];
			allPinsDropped = NO;
			break;
		} 
	}
	if (allPinsDropped) {
		[_pinDropTimer invalidate];
		[_pinDropTimer release];
		_pinDropTimer = nil;
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
		annotationView.canShowCallout = YES;
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
		
		UIImageView* imageView = nil;
		if (_shouldNotDropPins) {
			annotationView.alreadyOnMap = YES;
			imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_pin_complete.png"]] autorelease];
		} else {
			imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_pin.png"]] autorelease];
			// add its shadow
			if (_annotationShadowViews == nil) {
				_annotationShadowViews = [[NSMutableArray alloc] init];
			}
			UIImage* shadow = [UIImage imageNamed:@"map_pin_shadow.png"];
			UIImageView* annotationShadowView = [[[UIImageView alloc] initWithImage:shadow] autorelease];		// these are released after the pin drop animation
			[_annotationShadowViews addObject:annotationShadowView];
			[self.layer addSublayer:annotationShadowView.layer];
			annotationView.shadowView = annotationShadowView;
			
			annotationShadowView.center = CGPointMake(-50, -50);
		}
		annotationView.frame = imageView.frame;
		[annotationView addSubview:imageView];

		annotationView.center = CGPointMake(-50, -50);
	}
	
	if(nil != annotationView)
	{
		annotationView.mapView = self;
		
		// we need to insert the annotation view at the right spot in both the array and the layer tree. 
		// Annotations views should fall east-most first, but should be layered northern under southern
		BOOL addedToArray = NO;

		for (int idx = 0; idx < _annotationViews.count; idx++) {
			MITMapAnnotationView* prevAnnnotationView = [_annotationViews objectAtIndex:idx];
			
			if (annotation.coordinate.latitude > prevAnnnotationView.annotation.coordinate.latitude) {
				addedToArray = YES;
				
				[_annotationViews insertObject:annotationView atIndex:idx];
				
				CALayer* layer = [annotationView layer];
				[self.layer insertSublayer:layer below:prevAnnnotationView.layer];
								
				break;
			}
		}

		if (!addedToArray) {
			// just add them at the end. 
			[_annotationViews addObject:annotationView];
			[self.layer addSublayer:annotationView.layer];	//
		}

		
		// if any of these annotations have not been placed on the map yet, use the timer to drop them sequentially
		if (annotationView.alreadyOnMap) {
			[self positionAnnotationView:annotationView];
		} else {
			if (_pinDropTimer == nil) {
				_pinDropTimer = [[NSTimer scheduledTimerWithTimeInterval:kPinDropTimerFrequency target:self selector:@selector(pinDropTimerFired:) userInfo:nil repeats:YES] retain];
			}
		}
	}
	
}

- (void)addAnnotations:(NSArray *)annotations
{
	for (id<MKAnnotation> annotation in annotations)
	{
		[self addAnnotation:annotation];
	}
	
	
	if(_shouldNotDropPins && _annotationViews.count == 1)
	{ 
		MITMapAnnotationView * annotationView = [_annotationViews objectAtIndex:0];
		[self selectAnnotation:annotationView.annotation animated:NO withRecenter:NO];
	}
	
}

- (void)removeAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = [self viewForAnnotation:annotation];
    
    if (nil == annotationView) { NSLog(@"found an orphaned annotation %@", [annotation description]); }
	
	if(nil != annotationView)
	{
		
		UIImageView* shadowView = annotationView.shadowView;
		if(nil != shadowView)
		{
			[shadowView.layer removeFromSuperlayer];
			
			annotationView.shadowView = nil;
			[_annotationShadowViews removeObject:shadowView];
            //[shadowView release];
		}
		
		
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

- (void)removeAllAnnotations
{
	for (int idx = _annotations.count - 1; idx >= 0; idx--) {
		[self removeAnnotation:[_annotations objectAtIndex:idx]];
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
	
	if ([_mapDelegate respondsToSelector:@selector(annotationSelected:)]) {
		[_mapDelegate annotationSelected:annotation];
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
	
// there was an error connecting to the specified URL. 
- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request 
{
	
}

- (id<MKAnnotation>) currentAnnotation {
	return _currentCallout.annotation;
}

@end
