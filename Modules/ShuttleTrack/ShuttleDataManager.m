#import "ShuttleDataManager.h"
#import "ShuttleRoute.h"
#import "ShuttleStop.h"
#import "ShuttleRouteStop.h"
#import "CoreDataManager.h"
#import "MITConstants.h"

static ShuttleDataManager* s_dataManager = nil;

@interface ShuttleDataManager(Private)

-(void) sendRoutesToDelegates:(NSArray*)routes;
-(void) sendStopsToDelegates:(NSArray*)routes;
-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;
-(void) sendRouteToDelegates:(ShuttleRoute *)route forRouteID:(NSString*)routeID;

- (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID;
- (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID;
- (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error;
- (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID;

@end


@implementation ShuttleDataManager
@synthesize shuttleRoutes = _shuttleRoutes;
@synthesize shuttleRoutesByID = _shuttleRoutesByID;
@synthesize stopLocations = _stopLocations;
@synthesize stopLocationsByID = _stopLocationsByID;

NSString * const shuttlePathExtension = @"shuttles/";

+ (ShuttleDataManager *)sharedDataManager {
    @synchronized(self) {
        if (s_dataManager == nil) {
            s_dataManager = [[super allocWithZone:NULL] init]; 
        }
    }
	
    return s_dataManager;
}

-(void) dealloc
{
	[_shuttleRoutes release];
	[_shuttleRoutesByID release];
	
	[_registeredDelegates release];
	
	[super dealloc];
}


- (id)init {
    self = [super init];
    if (self) {
        _shuttleRoutes = nil;
        _shuttleRoutesByID = nil;
        _stopLocations = nil;
        _stopLocationsByID = nil;
        
        // populate route cache in memory
        _shuttleRoutes = [[NSMutableArray alloc] init];	
        _shuttleRoutesByID = [[NSMutableDictionary alloc] init];
        
        NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
        NSArray *cachedRoutes = [CoreDataManager objectsForEntity:ShuttleRouteEntityName
                                                matchingPredicate:matchAll
                                                  sortDescriptors:[NSArray arrayWithObject:sort]];
        [sort release];
        DLog(@"%d routes cached", [cachedRoutes count]);
        
        for (ShuttleRouteCache *cachedRoute in cachedRoutes) {
            NSString *routeID = cachedRoute.routeID;
            ShuttleRoute *route = [[ShuttleRoute alloc] initWithCache:cachedRoute];
            DLog(@"fetched route %@ from core data", route.routeID);
            [_shuttleRoutes addObject:route];
            [_shuttleRoutesByID setValue:route forKey:routeID];
            [route release];
        }
    }
	return self;
}

# pragma mark core data abstraction

- (NSArray *)shuttleStops
{
	NSArray *routeStops = [CoreDataManager objectsForEntity:ShuttleRouteStopEntityName
										  matchingPredicate:[NSPredicate predicateWithFormat:@"TRUEPREDICATE"]];
	NSMutableArray *stops = [NSMutableArray arrayWithCapacity:[routeStops count]];
	for (ShuttleRouteStop *routeStop in routeStops) {
		ShuttleStop *stop = [[[ShuttleStop alloc] initWithRouteStop:routeStop] autorelease];
		[stops addObject:stop];
	}
	
	return stops;
}

+ (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID
{
	return [[ShuttleDataManager sharedDataManager] shuttleRouteWithID:routeID];
}

- (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID
{
	return [_shuttleRoutesByID objectForKey:routeID];
}

+ (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID
{
	return [[ShuttleDataManager sharedDataManager] routeCacheWithID:routeID];
}

- (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"routeID LIKE %@", routeID];
	NSArray *routeCaches = [CoreDataManager objectsForEntity:ShuttleRouteEntityName matchingPredicate:pred];
	ShuttleRouteCache *routeCache = nil;
	if ([routeCaches count] == 0) {
		NSManagedObject *newRoute = [CoreDataManager insertNewObjectForEntityForName:ShuttleRouteEntityName];
		[newRoute setValue:routeID forKey:@"routeID"];
		routeCache = (ShuttleRouteCache *)newRoute;
	} else {
		routeCache = [routeCaches lastObject];
	}
	return routeCache;
}

+ (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error
{
	return [[ShuttleDataManager sharedDataManager] stopWithRoute:routeID stopID:stopID error:error];
}

- (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error
{
	ShuttleStop *stop = nil;
	ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
	if (route != nil) {
        for (ShuttleStop *aStop in route.stops) {
            if ([aStop.stopID isEqualToString:stopID]) {
                stop = aStop;
                break;
            }
        }
        
        if (stop == nil) {
            VLog(@"attempting to create new ShuttleStop for stop %@ on route %@", stopID, routeID);
            ShuttleStopLocation *stopLocation = [self stopLocationWithID:stopID];
            stop = [[[ShuttleStop alloc] initWithStopLocation:stopLocation routeID:routeID] autorelease];
        }
        
	} else {
		if (error != NULL) {
        NSString *message = [NSString stringWithFormat:@"route %@ does not exist", routeID];
        *error = [NSError errorWithDomain:@"MIT Mobile" code:4567 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil]];
    }
		return nil;
    }
	
	return stop;
}

+ (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID
{
	return [[ShuttleDataManager sharedDataManager] stopLocationWithID:stopID];
}

- (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID
{
	if (_stopLocations == nil) {
		// populate stop cache in memory
		
		_stopLocations = [[NSMutableArray alloc] init];
		_stopLocationsByID = [[NSMutableDictionary alloc] init];
		NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
		NSArray *stopLocations = [CoreDataManager objectsForEntity:ShuttleStopEntityName matchingPredicate:matchAll];
		
		for (ShuttleStopLocation *stopLocation in stopLocations) {
			NSString *stopID = [stopLocation stopID];
			[_stopLocations addObject:stopLocation];
			[_stopLocationsByID setObject:stopLocation forKey:stopID];
		}
	}
	
	ShuttleStopLocation *stopLocation = [_stopLocationsByID objectForKey:stopID];
	if (stopLocation == nil) {
		NSManagedObject *newStopLocation = [CoreDataManager insertNewObjectForEntityForName:ShuttleStopEntityName];
		[newStopLocation setValue:stopID forKey:@"stopID"];
		stopLocation = (ShuttleStopLocation *)newStopLocation;	
		[_stopLocations addObject:stopLocation];
		[_stopLocationsByID setObject:stopLocation forKey:stopID];
	}
	return stopLocation;
}

#pragma mark -

-(void) requestRoutes
{
	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	BOOL dispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"routes", @"command", @"true", @"compact", nil]
						   pathExtension:shuttlePathExtension];
	if (!dispatched) {
		WLog(@"%@", @"problem making routes api request");
	}
}


-(void) requestStop:(NSString*)stopID
{
	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	BOOL dispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"stopInfo", @"command", stopID, @"id", nil]
						   pathExtension:shuttlePathExtension];
	if (!dispatched) {
		WLog(@"%@", @"problem making single stop api request");
	}
}

-(void) requestRoute:(NSString*)routeID
{	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	BOOL dispatched = [api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"routeInfo", @"command", routeID, @"id", @"true", @"full", nil]
						   pathExtension:shuttlePathExtension];
	if (!dispatched) {
		WLog(@"%@", @"problem making single route api request");
	}
}

#pragma mark Delegate Message distribution

-(void) sendRoutesToDelegates:(NSArray*)routes
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(routesReceived:)]) {
			[delegate routesReceived:routes];
		}
	}
}

-(void) sendStopsToDelegates:(NSArray*)stops
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(stopsReceived:)]) {
			[delegate stopsReceived:stops];
		}
	}
}

-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(stopInfoReceived:forStopID:)]) {
			[delegate stopInfoReceived:shuttleStopSchedules forStopID:stopID];
		}
	}
}

-(void) sendRouteToDelegates:(ShuttleRoute *)route forRouteID:(NSString*)routeID
{	
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(routeInfoReceived:forRouteID:)]) {
			[delegate routeInfoReceived:route forRouteID:routeID];
		}
	}
}

#pragma mark Delegate registration
-(void) registerDelegate:(id<ShuttleDataManagerDelegate>)delegate
{
	if (nil == _registeredDelegates) {
		_registeredDelegates = [[NSMutableArray alloc] initWithCapacity:1];
	}
	
	// make sure it is not already in there
	if (NSNotFound == [_registeredDelegates indexOfObject:delegate]) {
		[_registeredDelegates addObject:delegate];
	}

}

-(void) unregisterDelegate:(id<ShuttleDataManagerDelegate>)delegate
{
	[_registeredDelegates removeObject:delegate];

	if ([[CoreDataManager managedObjectContext] hasChanges]) {
		[CoreDataManager saveData];
	}
}


#pragma mark JSONLoadedDelegate

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result
{	
	if ([[request.params valueForKey:@"command"] isEqualToString:@"routes"] && [result isKindOfClass:[NSArray class]]) {

		BOOL routesChanged = NO;
		
		NSMutableArray *routeIDs = [[NSMutableArray alloc] initWithCapacity:[result count]];
        NSInteger sortOrder = 0;
		
		for (NSDictionary *routeInfo in result) {

			NSString *routeID = [routeInfo objectForKey:@"route_id"];

			[routeIDs addObject:routeID];
			
			ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
			if (route == nil) {
				route = [[[ShuttleRoute alloc] initWithDictionary:routeInfo] autorelease];
				[_shuttleRoutes addObject:route];
				[_shuttleRoutesByID setValue:route forKey:routeID];
				routesChanged = YES;
			}
			[route updateInfo:routeInfo];
            if (route.sortOrder != sortOrder) {
                route.sortOrder = sortOrder;
                routesChanged = YES;
            }
            sortOrder++;
		}

		// prune routes that don't exist anymore
		NSPredicate *missing = [NSPredicate predicateWithFormat:@"NOT (routeID IN %@)", routeIDs];
		NSArray *missingRoutes = [_shuttleRoutes filteredArrayUsingPredicate:missing];
		
		for (ShuttleRoute *route in missingRoutes) {
			NSString *routeID = route.routeID;
			[CoreDataManager deleteObject:route.cache];
			[_shuttleRoutesByID setValue:nil forKey:routeID];
			[_shuttleRoutes removeObject:route];
			route = nil;
			routesChanged = YES;
		}
		
		if (routesChanged) {
			[CoreDataManager saveData];
		}
		
		[routeIDs release];
		
		[self sendRoutesToDelegates:_shuttleRoutes];
	}
	else if ([[request.params valueForKey:@"command"] isEqualToString:@"stopInfo"] && [result isKindOfClass:[NSDictionary class]]) {

		NSArray* routesAtStop = [result objectForKey:@"stops"]; // the api should've called this "routes", this is confusing
		
		NSMutableArray* schedules = [NSMutableArray arrayWithCapacity:routesAtStop.count];
		NSString* stopID = [request.params objectForKey:@"id"];
		
		for (NSDictionary* routeAtStop in routesAtStop) 
		{
            NSError *error = nil;
			ShuttleStop *stop = [ShuttleDataManager stopWithRoute:[routeAtStop objectForKey:@"route_id"] stopID:stopID error:&error];
            
            if (error != nil) {
                ELog(@"error getting shuttle stop. code: %d; userinfo: %@", error.code, error.userInfo);
            }

            if (stop != nil) {
                NSNumber* next = [routeAtStop objectForKey:@"next"];
                if (!next) {
                    next = [routeAtStop objectForKey:@"nextScheduled"];
                }
                stop.nextScheduled = [next doubleValue];
                NSNumber* now = [result objectForKey:@"now"];
                stop.now = [now doubleValue];
                
                stop.predictions = [routeAtStop objectForKey:@"predictions"];
                
                [schedules addObject:stop];
            }
		}
		
		[self sendStopToDelegates:schedules forStopID:stopID];
	}
	else if ([[request.params valueForKey:@"command"] isEqualToString:@"routeInfo"] && [result isKindOfClass:[NSDictionary class]]) {

		NSString *routeID = [result objectForKey:@"route_id"];
		
		ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
		if (route == nil) {
			ShuttleRoute *route = [[[ShuttleRoute alloc] init] autorelease];
			[_shuttleRoutes addObject:route];
			[_shuttleRoutesByID setValue:route forKey:routeID];
		}
		[route updateInfo:result];
		
		[self sendRouteToDelegates:route forRouteID:route.routeID];
	}
}


- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	if ([[request.params valueForKey:@"command"] isEqualToString:@"routes"]) {
		[self sendRoutesToDelegates:nil];
	}
	else if ([[request.params valueForKey:@"command"] isEqualToString:@"stops"]) {
		[self sendStopsToDelegates:nil];
	}
	else if ([[request.params valueForKey:@"command"] isEqualToString:@"stopInfo"]) {
		[self sendStopToDelegates:nil forStopID:[request.params valueForKey:@"id"]];
	}
	else if ([[request.params valueForKey:@"command"] isEqualToString:@"routeInfo"]) {
		[self sendRouteToDelegates:nil forRouteID:[request.params valueForKey:@"id"]];
	}
}

-(BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	// since the logic for when errors are silent versus shown is a little complicated
	// we just turn off error messages by default and leave it to the View Controllers to implement error messages
	// this has the disadvantage of not being to able to distinguish network errors from timeout errors
	return NO;
}

@end
