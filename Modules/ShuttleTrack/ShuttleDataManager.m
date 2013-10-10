#import "ShuttleDataManager.h"
#import "ShuttleRoute.h"
#import "ShuttleStop.h"
#import "ShuttleRouteStop2.h"
#import "CoreDataManager.h"
#import "MITConstants.h"
#import "MobileRequestOperation.h"

static ShuttleDataManager* s_dataManager = nil;

@interface ShuttleDataManager(Private)

-(void) sendRoutesToDelegates:(NSArray*)routes;
-(void) sendStopsToDelegates:(NSArray*)routes;
-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;
-(void) sendRouteToDelegates:(ShuttleRoute *)route forRouteID:(NSString*)routeID;

- (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID;
- (ShuttleRouteCache2 *)routeCacheWithID:(NSString *)routeID;
- (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error;
- (ShuttleStopLocation2 *)stopLocationWithStop:(ShuttleStop *)stop;

@end


@implementation ShuttleDataManager
@synthesize shuttleRoutes = _shuttleRoutes;
@synthesize shuttleRoutesByID = _shuttleRoutesByID;
@synthesize stopLocations = _stopLocations;
@synthesize stopLocationsByID = _stopLocationsByID;

NSString * const shuttlePathExtension = @"/apis/shuttles/routes";
NSString * const shuttleStopPath = @"/stops/";

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
        DDLogVerbose(@"%d routes cached", [cachedRoutes count]);
        
        for (ShuttleRouteCache2 *cachedRoute in cachedRoutes) {
            NSString *routeID = cachedRoute.routeID;
            ShuttleRoute *route = [[ShuttleRoute alloc] initWithCache:cachedRoute];
            DDLogVerbose(@"fetched route %@ from core data", route.routeID);
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
	for (ShuttleRouteStop2 *routeStop in routeStops) {
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

+ (ShuttleRouteCache2 *)routeCacheWithID:(NSString *)routeID;
{
	return [[ShuttleDataManager sharedDataManager] routeCacheWithID:routeID];
}

- (ShuttleRouteCache2 *)routeCacheWithID:(NSString *)routeID;
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"routeID LIKE %@", routeID];
	NSArray *routeCaches = [CoreDataManager objectsForEntity:ShuttleRouteEntityName matchingPredicate:pred];
	ShuttleRouteCache2 *routeCache = nil;
	if ([routeCaches count] == 0) {
		NSManagedObject *newRoute = [CoreDataManager insertNewObjectForEntityForName:ShuttleRouteEntityName];
		[newRoute setValue:routeID forKey:@"routeID"];
		routeCache = (ShuttleRouteCache2 *)newRoute;
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
            DDLogVerbose(@"attempting to create new ShuttleStop for stop %@ on route %@", stopID, routeID);
            ShuttleStop *newStop = [[ShuttleStop alloc] init];
            newStop.stopID = stopID;
            ShuttleStopLocation2 *stopLocation = [self stopLocationWithStop:newStop];
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

+ (ShuttleStopLocation2 *)stopLocationWithStop:(ShuttleStop *)stop
{
	return [[ShuttleDataManager sharedDataManager] stopLocationWithStop:stop];
}

- (ShuttleStopLocation2 *)stopLocationWithStop:(ShuttleStop *)stop
{
	if (_stopLocations == nil) {
		// populate stop cache in memory
		
		_stopLocations = [[NSMutableArray alloc] init];
		_stopLocationsByID = [[NSMutableDictionary alloc] init];
		NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
		NSArray *stopLocations = [CoreDataManager objectsForEntity:ShuttleStopEntityName matchingPredicate:matchAll];
		
		for (ShuttleStopLocation2 *stopLocation in stopLocations) {
			NSString *stopID = [stopLocation stopID];
			[_stopLocations addObject:stopLocation];
			[_stopLocationsByID setObject:stopLocation forKey:stopID];
		}
	}
	
	ShuttleStopLocation2 *stopLocation = [_stopLocationsByID objectForKey:stop.stopID];
  
	if (stopLocation == nil) {
		NSManagedObject *newStopLocation = [CoreDataManager insertNewObjectForEntityForName:ShuttleStopEntityName];
		[newStopLocation setValue:stop.stopID forKey:@"stopID"];
        stopLocation = (ShuttleStopLocation2 *)newStopLocation;
        stopLocation.title = stop.title;
        stopLocation.latitude = [NSNumber numberWithDouble: stop.latitude];
        stopLocation.longitude = [NSNumber numberWithDouble: stop.longitude];
		[_stopLocations addObject:stopLocation];
		[_stopLocationsByID setObject:stopLocation forKey:stop.stopID];
        [CoreDataManager saveData];
	}
	return stopLocation;
}

#pragma mark -

-(void) requestRoutes
{
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithRelativePath:shuttlePathExtension parameters:nil] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error && [jsonResult isKindOfClass:[NSArray class]]) {
            
            BOOL routesChanged = NO;
            
            NSMutableArray *routeIDs = [[NSMutableArray alloc] initWithCapacity:[jsonResult count]];
            NSInteger sortOrder = 0;
            
            for (NSDictionary *routeInfo in jsonResult) {
                NSString *routeID = [routeInfo objectForKey:@"id"];
                
                if ([routeID length]) {
                    [routeIDs addObject:routeID];
                    
                    ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
                    if (route == nil) {
                        route = [[[ShuttleRoute alloc] initWithDictionary:routeInfo] autorelease];
                        
                        if (route) {
                            [_shuttleRoutes addObject:route];
                            [_shuttleRoutesByID setObject:route
                                                   forKey:routeID];
                            routesChanged = YES;
                        }
                    }
                    
                    if (route) {
                        [route updateInfo:routeInfo];
                        if (route.sortOrder != sortOrder) {
                            route.sortOrder = sortOrder;
                            routesChanged = YES;
                        }
                        sortOrder++;
                    }
                }
            }
            
            // prune routes that don't exist anymore
            NSPredicate *missing = [NSPredicate predicateWithFormat:@"NOT (routeID IN %@)", routeIDs];
            NSArray *missingRoutes = [_shuttleRoutes filteredArrayUsingPredicate:missing];
            
            for (ShuttleRoute *route in missingRoutes) {
                NSString *routeID = route.routeID;
                [CoreDataManager deleteObject:route.cache];
                [_shuttleRoutesByID removeObjectForKey:routeID];
                [_shuttleRoutes removeObject:route];
                route = nil;
                routesChanged = YES;
            }
            
            if (routesChanged) {
                [CoreDataManager saveData];
            }
            
            [routeIDs release];
            
            [self sendRoutesToDelegates:_shuttleRoutes];

        } else {
            [self sendRoutesToDelegates:nil];
        }
    };
    
    [[NSOperationQueue mainQueue] addOperation:request];
}


-(void) requestStop:(NSString*)stopID
{
    if (schedules) {
        [schedules release];
        schedules = nil;
    }
    schedules = [[NSMutableArray alloc] init];
    
    for (ShuttleRoute *route in _shuttleRoutes)
    {
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithRelativePath:[NSString stringWithFormat:@"%@/%@%@%@", shuttlePathExtension, route.routeID ,shuttleStopPath, stopID]
                                                                                    parameters:nil];
        request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
            if (!error && [jsonResult isKindOfClass:[NSDictionary class]]) {
                if ([jsonResult objectForKey:@"id"]) {
                    ShuttleStop *stop = [[ShuttleStop alloc] initWithDictionary:jsonResult];
                    stop.routeName = route;
                    [schedules addObject:stop];
                    [self sendStopToDelegates:schedules forStopID:stopID];
                }
            } else {
                [self sendStopToDelegates:nil forStopID:stopID];
            }
        };
        
        [[NSOperationQueue mainQueue] addOperation:request];
    }
}

-(void) requestRoute:(NSString*)routeID
{
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithRelativePath:[NSString stringWithFormat:@"%@/%@", shuttlePathExtension, routeID]
                                                                                 parameters:nil] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error && [jsonResult isKindOfClass:[NSDictionary class]]) {
                        
            NSString *routeID = [jsonResult objectForKey:@"id"];
            
            ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
            if (route == nil) {
                ShuttleRoute *route = [[[ShuttleRoute alloc] init] autorelease];
                [_shuttleRoutes addObject:route];
                [_shuttleRoutesByID setValue:route forKey:routeID];
            }
            [route updateInfo:jsonResult];
            
            [self sendRouteToDelegates:route forRouteID:route.routeID];

        } else {
            [self sendRouteToDelegates:nil forRouteID:routeID];
        }
    };
    
    [[NSOperationQueue mainQueue] addOperation:request];
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


@end
