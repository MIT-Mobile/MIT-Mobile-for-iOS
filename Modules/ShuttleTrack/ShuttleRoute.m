#import "ShuttleRoute.h"
#import "ShuttleStop.h" 
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopLocation.h"
#import "ShuttleLocation.h"
#import "ShuttleRouteStop.h"
#import "ShuttleDataManager.h"
#import "CoreDataManager.h"
#import "ShuttleVehicle.h"
#import "ShuttlePrediction.h"

@implementation ShuttleRoute

// live properties
@synthesize tag = _tag;
@synthesize gpsActive = _gpsActive;
@synthesize isRunning = _isRunning;
@synthesize liveStatusFailed = _liveStatusFailed;
@synthesize vehicleLocations = _vehicleLocations;
@synthesize cache = _cache;

// cached properties
//@dynamic title;
@dynamic summary;
//@dynamic interval;
@dynamic isSafeRide;
//@dynamic stops;
//@dynamic routeID;
@dynamic sortOrder;

@dynamic fullSummary;


// NEW API
@synthesize routeID = _routeID;
@synthesize group = _group;
@synthesize url = _url;
@synthesize title = _title;
@synthesize description = _description;
@synthesize active = _active;
@synthesize predictable = _predictable;
@synthesize interval = _interval;
@synthesize stops = _stops;
@synthesize vehicles = _vehicles;
@synthesize path = _path;
//@dynamic path;


#pragma mark Getters and setters

- (NSString *)title {
	return self.cache.title;
}

- (void)setTitle:(NSString *)title {
	if (title != nil && self.cache != nil)
		self.cache.title = title;
}

- (NSString *)summary {
	return self.cache.summary;
}

- (void)setSummary:(NSString *)summary {
	if (summary != nil && self.cache != nil)
		self.cache.summary = summary;
}

- (NSString *)routeID {
	return self.cache.routeID;
}

- (void)setRouteID:(NSString *)routeID {
	if (routeID != nil) {
		if (self.cache == nil) {
			self.cache = [ShuttleDataManager routeCacheWithID:routeID];
		}
	} else {
		self.cache.routeID = routeID;
	}
}

- (NSInteger)interval {
	return [self.cache.interval intValue];
}

- (void)setInterval:(NSInteger)interval {
	if (self.cache != nil)
		self.cache.interval = [NSNumber numberWithInt:interval];
}

- (BOOL)isSafeRide {
	return [self.cache.isSafeRide boolValue];
}

- (void)setIsSafeRide:(BOOL)isSafeRide {
	if (self.cache != nil)
		self.cache.isSafeRide = [NSNumber numberWithBool:isSafeRide];
}

- (NSMutableArray *)stops {
	return _stops;
}

- (void)setStops:(NSMutableArray *)stops {
	
	BOOL pathShouldUpdate = NO;
	
	if (_stopAnnotations == nil) {
		_stopAnnotations = [[NSMutableArray alloc] initWithCapacity:[stops count]];
		pathShouldUpdate = YES;
	}
	
	if (_pathLocations == nil) {
		pathShouldUpdate = YES;
	}
	
	NSMutableArray *newStops = [NSMutableArray array];
//	BOOL hasNewStops = NO;
//    BOOL pathChanged = NO;
	
	NSMutableSet *oldRouteStops = [[NSMutableSet alloc] initWithSet:self.cache.stops];
//	NSMutableSet *newRouteStops = [NSMutableSet setWithCapacity:[stops count]];
	
	NSInteger order = 0;
	for (NSDictionary *stopInfo in stops) {
		ShuttleStop *shuttleStop = [[ShuttleStop alloc] initWithDictionary:stopInfo];
        
        ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
        [_stopAnnotations addObject:annotation];
        
        // TODO: add check for old stops
        /*
		BOOL isOldStop = NO;
		
		NSString *stopID = [stopInfo objectForKey:@"id"];
		
		for (ShuttleStop *stop in _stops) {
			if ([stop.stopID isEqualToString:stopID]) {
				shuttleStop = stop;
				isOldStop = YES;
                [newRouteStops addObject:shuttleStop.routeStop];
				break;
			}
		}
		
		if (!isOldStop) {
			ShuttleStopLocation *stopLocation = [ShuttleDataManager stopLocationWithID:stopID];				
			shuttleStop = [[[ShuttleStop alloc] initWithStopLocation:stopLocation routeID:self.routeID] autorelease];
			
			[newRouteStops addObject:shuttleStop.routeStop];
			
			ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
			[_stopAnnotations addObject:annotation];

			hasNewStops = YES;
		}
         */
		
        // TODO: move to somewhere else. Stops has no path anymore.
        /*
        NSArray *newPath = [stopInfo objectForKey:@"path"];
        if (newPath == nil) { newPath = [NSArray array]; }
        if ([shuttleStop.path isEqualToArray: newPath] == NO) {
            pathChanged = YES;
        }
         */
        
        
		[shuttleStop updateInfo:stopInfo];
		[newStops addObject:shuttleStop];

		shuttleStop.order = order;
		order++;
	}
    
    _stops = [newStops retain];
    [self calculateUpcoming];
	
    // TODO: work with cached stops. Don't have this functionality yet.
    /*
	// check if we added new stops or shouldn't include old ones
	if (pathChanged || hasNewStops || [_stops count] > [stops count]) {
		
		_stops = [newStops retain];
		
		// prune cached stops no longer on the route
		self.cache.stops = newRouteStops;
		[oldRouteStops minusSet:newRouteStops];
        DDLogVerbose(@"deleting route stops: %@", [oldRouteStops description]);
		[CoreDataManager deleteObjects:[oldRouteStops allObjects]];
		
		pathShouldUpdate = YES;
	}
     
	if (pathShouldUpdate) {
		// get rid of obsolete map annotations
		NSMutableArray *oldStops = [[NSMutableArray alloc] initWithCapacity:[stops count]];
		for (ShuttleStopMapAnnotation *annotation in _stopAnnotations) {
			if (![_stops containsObject:annotation.shuttleStop]) {
				[oldStops addObject:annotation];
			}
		}
		for (ShuttleStopMapAnnotation *annotation in oldStops) {
			[_stopAnnotations removeObject:annotation];
		}
		[oldStops release];
		
		[self updatePath];
	}
     */
	
	[oldRouteStops release];
}

- (void) calculateUpcoming
{
    for (ShuttleStop *stop in _stops)
    {
        stop.upcoming = false;
    }
    
    if (_predictable) {
        [self setUpcomingByPredictions];
    } else {
        [self setUpcomingBySchedule];
    }
}

- (void) setUpcomingBySchedule
{
    long minTimestamp = [[_stops objectAtIndex:0] next];
    
    long now = [[NSDate date] timeIntervalSince1970];
    int upcomingIndex = 0;
    
    for (int i = 0; i < [_stops count]; i++) {
        ShuttleStop *stop = [_stops objectAtIndex:i];
        if (stop.next < minTimestamp && stop.next > now) {
            minTimestamp = stop.next;
            upcomingIndex = i;
        }
    }
    [((ShuttleStop *)[_stops objectAtIndex:upcomingIndex]) setUpcoming:YES];
}

- (void) setUpcomingByPredictions
{
    long now = [[NSDate date] timeIntervalSince1970];
    for (ShuttleVehicle *vehicle in _vehicles) {
        NSString *upcomingID = [[NSString alloc] init];
        long vehicleMin = now + (60 * 60 * 24);
        bool hasUpcoming = false;
        
        for (int i = 0; i < [_stops count]; i++) {
            ShuttleStop *stop = [_stops objectAtIndex:i];
            long predictionMin = vehicleMin;
            bool hasMinTime = false;
            
            for (ShuttlePrediction *prediction in stop.predictions) {
                long predictionTime = prediction.timestamp / 1000;
                if ([prediction.vehicleID isEqualToString:vehicle.vehicleID] &&
                    predictionTime < predictionMin &&
                    predictionTime > now) {
                    predictionMin = predictionTime;
                    hasMinTime = true;
                }
            }
            
            if (hasMinTime && predictionMin < vehicleMin) {
                vehicleMin = predictionMin;
                upcomingID = stop.stopID;
                hasUpcoming = true;
            }
        }
        
        if (hasUpcoming) {
            for (ShuttleStop *stop in _stops) {
                if ([stop.stopID isEqualToString:(upcomingID)]) {
                    stop.upcoming = true;
                    break;
                }
            }
        }
    }
}

- (NSInteger)sortOrder {
    return [self.cache.sortOrder intValue];
}

- (void)setSortOrder:(NSInteger)order {
    self.cache.sortOrder = [NSNumber numberWithInt:order];
}

#pragma mark -

- (void)updateInfo:(NSDictionary *)routeInfo
{
    self.routeID = [routeInfo objectForKey:@"id"];
	self.title = [routeInfo objectForKey:@"title"];
    self.url = [routeInfo objectForKey:@"url"];
    self.description = [routeInfo objectForKey:@"description"];
    self.group = [routeInfo objectForKey:@"group"];
    self.active = [[routeInfo objectForKey:@"active"] boolValue];
    self.predictable = [[routeInfo objectForKey:@"predictable"] boolValue];
	self.interval = [[routeInfo objectForKey:@"interval"] intValue];
    
    // Get stops
	NSArray *stops = [routeInfo objectForKey:@"stops"];
	if (stops) {
		self.stops = (NSMutableArray *)stops;
	}
    
    // Get vehicles
    NSArray *vehicles = [routeInfo objectForKey:@"vehicles"];
    if (vehicles){
        NSMutableArray *vehiclesArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [vehicles count]; i++) {
            NSDictionary *jVehicle = [vehicles objectAtIndex:i];
            ShuttleVehicle *vehicle = [[ShuttleVehicle alloc] initWithDictionary:jVehicle];
            [vehiclesArray addObject:vehicle];
        }
        self.vehicles = vehiclesArray;
    }
    
    NSDictionary *path = [routeInfo objectForKey:@"path"];
    if (path)
    {
        _path= [[ShuttleRoutePath alloc] initWithDictionary:path];
    }
}

- (void)getStopsFromCache
{
	[_stops release];
	_stops = nil;
	
	[_stopAnnotations release];
	_stopAnnotations = nil;
	
	NSSet *cachedStops = self.cache.stops;
	_stops = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
	_stopAnnotations = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
	NSArray *sortedStops = [[cachedStops allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];		
	[sortDescriptor release];
	
	for (ShuttleRouteStop *routeStop in sortedStops) {
        NSError *error;
		ShuttleStop *shuttleStop = [ShuttleDataManager stopWithRoute:self.routeID stopID:[routeStop stopID] error:&error]; // should always be nil
		if (shuttleStop == nil) {
			shuttleStop = [[[ShuttleStop alloc] initWithRouteStop:routeStop] autorelease];
		}
		
		[_stops addObject:shuttleStop];

		ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
		[_stopAnnotations addObject:annotation];
	}
		
	if (_pathLocations == nil) {
		[self updatePath];
	}
}

- (void)updatePath
{
	if (_pathLocations != nil) {
		[_pathLocations removeAllObjects];
		_pathLocations = nil;
	}
	
	_pathLocations = [[NSMutableArray alloc] init];

	for (ShuttleStop *stop in _stops) {
		for(NSDictionary* pathComponent in stop.path) {
			CLLocation* location = [[[CLLocation alloc] initWithLatitude:[[pathComponent objectForKey:@"lat"] doubleValue]
															   longitude:[[pathComponent objectForKey:@"lon"] doubleValue]
									 ] autorelease];
			
			[_pathLocations addObject:location];
		}
	}	
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self != nil) {
		self.routeID = [dict objectForKey:@"id"];
		_vehicleLocations = nil;
		_pathLocations = nil;
		_stopAnnotations = nil;
		_liveStatusFailed = NO;
		
		[self updateInfo:dict];
		[self getStopsFromCache];
    }
    return self;
}

- (id)initWithCache:(ShuttleRouteCache *)cachedRoute
{
    if (self != nil) {
		self.cache = cachedRoute;
		_liveStatusFailed = NO;
		_stops = nil;
    }
    return self;
}

-(void) dealloc
{
	self.tag = nil;
	self.cache = nil;
	
	[_stops release];
	[_vehicleLocations release];	
	[_pathLocations release];
	[_stopAnnotations release];
	
	[super dealloc];
}

- (NSString *)fullSummary 
{
	NSString* summaryString = [NSString stringWithFormat:@"Route loop repeats every %d minutes.", self.interval]; //self.interval];
	if (nil != self.summary) {
		summaryString = [NSString stringWithFormat:@"%@ %@", self.description, summaryString];
	}
	
    return [NSString stringWithFormat:@"%@\n%@", [self trackingStatus], summaryString];
}

- (NSString *)trackingStatus
{
	NSString *summaryString = nil;
    
	if (_liveStatusFailed) {
		return @"Real time tracking failed to load.";
	}
	
//	ShuttleStop *aStop = [self.stops lastObject];
//	if (aStop.next) { // we have something from the server
//		if (self.vehicleLocations && self.vehicleLocations.count > 0) {
//			summaryString = @"Real time bus tracking online.";
//		} else if (self.isRunning) {
//			summaryString = @"Tracking offline. Following schedule.";
//		} else {
//			summaryString = @"Bus not running. Following schedule.";
//		}
//	} else {
//		summaryString = @"Loading...";
//	}
    
    if (self.active) {
        if (self.predictable) {
            summaryString = @"Real time bus tracking online.";
        } else {
            summaryString = @"Tracking offline. Following schedule.";
        }
    } else {
        summaryString = @"Bus not running. Following schedule.";
    }
    
	
	return summaryString;
}

#pragma mark -
#pragma mark Useful Overrides

- (NSString *)description {
    return self.title;
}

// override -isEqual: and -hash so that any ShuttleRoute objects with the same self.tag will be considered the same. Useful for finding objects in collections like -[NSArray indexOfObject:].
- (BOOL)isEqual:(id)anObject {
    ShuttleRoute *otherRoute = nil;
    if (anObject && [anObject isKindOfClass:[ShuttleRoute class]]) {
        otherRoute = (ShuttleRoute *)anObject;
    }
    //return (otherRoute && [self.tag isEqual:otherRoute.tag]);

	// backend was changed so that there is no difference between nextbus route tags and our internal route id
	// if we change that for some reason, the API should pick one or the other system and present
	// a single consistent set of route identifiers.
	return (otherRoute && [self.routeID	isEqual:otherRoute.routeID]);
}

- (NSUInteger)hash {
    //return [self.tag hash];
	return [self.routeID hash];
}

- (NSComparisonResult)compare:(ShuttleRoute *)aRoute {
    return [self.title compare:aRoute.title];
}

#pragma mark MITMapRoute delegation

// array of CLLocations making up the path of this route
-(NSArray*) pathLocations
{
    return self.path.segments;
}

-(double) minLat
{
    return self.path.minLat;
}

-(double) minLon
{
    return self.path.minLon;
}

-(double) maxLat
{
    return self.path.maxLat;
}

-(double) maxLon
{
    return self.path.maxLon;
}

// array of MKAnnotations that are to be included with this route
-(NSArray*) annotations
{
	return _stopAnnotations;
}

- (UIColor *)strokeColor {
	return [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75];
}

- (UIColor *)fillColor {
	return [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75];
}

// width of the route line to be rendered
-(CGFloat) lineWidth
{
	return 3.0;
}

- (NSArray *)lineDashPattern {
    return nil;
}
@end
