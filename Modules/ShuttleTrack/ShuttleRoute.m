#import "ShuttleRoute.h"
#import "ShuttleStop.h" 
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopLocation.h"
#import "ShuttleLocation.h"
#import "ShuttleRouteStop.h"
#import "ShuttleDataManager.h"
#import "CoreDataManager.h"

@interface ShuttleRoute ()
{
    NSMutableArray *_stops;
}

@end

@implementation ShuttleRoute

// cached properties
@dynamic title;
@dynamic summary;
@dynamic interval;
@dynamic isSafeRide;
@dynamic routeID;
@dynamic sortOrder;

@dynamic fullSummary;


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
	BOOL hasNewStops = NO;
    BOOL pathChanged = NO;
	
	NSMutableSet *oldRouteStops = [[NSMutableSet alloc] initWithSet:self.cache.stops];
	NSMutableSet *newRouteStops = [NSMutableSet setWithCapacity:[stops count]];
	
	NSInteger order = 0;
	for (NSDictionary *stopInfo in stops) {
		ShuttleStop *shuttleStop = nil;
		BOOL isOldStop = NO;
		
		NSString *stopID = stopInfo[@"stop_id"];
		if (stopID == nil) {
			stopID = stopInfo[@"id"];
			
		}
		
		for (ShuttleStop *stop in self.stops) {
			if ([stop.stopID isEqualToString:stopID]) {
				shuttleStop = stop;
				isOldStop = YES;
                [newRouteStops addObject:shuttleStop.routeStop];
				break;
			}
		}
		
		if (!isOldStop) {
			ShuttleStopLocation *stopLocation = [ShuttleDataManager stopLocationWithID:stopID];				
			shuttleStop = [[ShuttleStop alloc] initWithStopLocation:stopLocation routeID:self.routeID];
			
			[newRouteStops addObject:shuttleStop.routeStop];
			
			ShuttleStopMapAnnotation* annotation = [[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop];
			[_stopAnnotations addObject:annotation];

			hasNewStops = YES;
		}
		
        NSArray *newPath = stopInfo[@"path"];
        if (newPath == nil) { newPath = [NSArray array]; }
        if ([shuttleStop.path isEqualToArray: newPath] == NO) {
            pathChanged = YES;
        }
		[shuttleStop updateInfo:stopInfo];
		[newStops addObject:shuttleStop];

		shuttleStop.order = order;
		order++;
	}
	
	// check if we added new stops or shouldn't include old ones
	if (pathChanged || hasNewStops || [self.stops count] > [stops count]) {
		
		_stops = newStops;
		
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
			if (![self.stops containsObject:annotation.shuttleStop]) {
				[oldStops addObject:annotation];
			}
		}
		for (ShuttleStopMapAnnotation *annotation in oldStops) {
			[_stopAnnotations removeObject:annotation];
		}
		
		[self updatePath];
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
	self.title = routeInfo[@"title"];
	self.summary = routeInfo[@"summary"];
	self.interval = [routeInfo[@"interval"] intValue];
	self.isSafeRide = [routeInfo[@"isSafeRide"] boolValue];
	
	self.tag = routeInfo[@"tag"];
	self.gpsActive = [routeInfo[@"gpsActive"] boolValue];
	self.isRunning = [routeInfo[@"isRunning"] boolValue];
	
	NSArray *stops = routeInfo[@"stops"];
	if (stops) {
		self.stops = (NSMutableArray *)stops;
        for (ShuttleStop *aStop in self.stops) {
            aStop.now = [routeInfo[@"now"] doubleValue];
        }
	}
	
	NSArray* vehicleLocations = routeInfo[@"vehicleLocations"];
	if (vehicleLocations && ![[NSNull null] isEqual:vehicleLocations])
	{
		self.vehicleLocations = nil;
		
		NSMutableArray* formattedVehicleLocations = [[NSMutableArray alloc] initWithCapacity:[vehicleLocations count]];
		for (NSDictionary* dictionary in vehicleLocations) {
			ShuttleLocation* shuttleLocation = [[ShuttleLocation alloc] initWithDictionary:dictionary];
			[formattedVehicleLocations addObject:shuttleLocation];
		}
		self.vehicleLocations = formattedVehicleLocations;
	}
}

- (void)getStopsFromCache
{
	self.stops = nil;
	_stopAnnotations = nil;
	
	NSSet *cachedStops = self.cache.stops;
	self.stops = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
	_stopAnnotations = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
	NSArray *sortedStops = [[cachedStops allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];		
	
	for (ShuttleRouteStop *routeStop in sortedStops) {
        NSError *error;
		ShuttleStop *shuttleStop = [ShuttleDataManager stopWithRoute:self.routeID stopID:[routeStop stopID] error:&error]; // should always be nil
		if (shuttleStop == nil) {
			shuttleStop = [[ShuttleStop alloc] initWithRouteStop:routeStop] ;
		}
		
		[self.stops addObject:shuttleStop];

		ShuttleStopMapAnnotation* annotation = [[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop];
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

	for (ShuttleStop *stop in self.stops) {
		for(NSDictionary* pathComponent in stop.path) {
			CLLocation* location = [[CLLocation alloc] initWithLatitude:[pathComponent[@"lat"] doubleValue]
															   longitude:[pathComponent[@"lon"] doubleValue]
									 ];
			
			[_pathLocations addObject:location];
		}
	}	
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self != nil) {
		self.routeID = dict[@"route_id"];
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
		self.stops = nil;
    }
    return self;
}

- (NSString *)fullSummary 
{
	NSString* summaryString = [NSString stringWithFormat:@"Route loop repeats every %d minutes.", self.interval]; //self.interval];
	if (nil != self.summary) {
		summaryString = [NSString stringWithFormat:@"%@ %@", self.summary, summaryString];
	}
	
    return [NSString stringWithFormat:@"%@\n%@", [self trackingStatus], summaryString];
}

- (NSString *)trackingStatus
{
	NSString *summaryString = nil;
	
	if (_liveStatusFailed) {
		return @"Real time tracking failed to load.";
	}
	
	ShuttleStop *aStop = [self.stops lastObject];
	if (aStop.nextScheduled) { // we have something from the server
		if (self.vehicleLocations && [self.vehicleLocations count] > 0) {
			summaryString = @"Real time bus tracking online.";
		} else if (self.isRunning) {
			summaryString = @"Tracking offline. Following schedule.";
		} else {
			summaryString = @"Bus not running. Following schedule.";
		}
	} else {
		summaryString = @"Loading...";
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
	return _pathLocations;
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
