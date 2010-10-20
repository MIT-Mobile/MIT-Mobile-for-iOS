
#import "ShuttleDataManager.h"
#import "NSString+SBJSON.h"
#import "ShuttleRoute.h"
#import "ShuttleStop.h"
#import "RouteStopSchedule.h"

static ShuttleDataManager* s_dataManager = nil;

@interface ShuttleDataManager ()

@property (nonatomic, readonly) NSString *s_apiRoutes;
@property (nonatomic, readonly) NSString *s_apiStops;
@property (nonatomic, readonly) NSString *s_apiRouteInfo;
@property (nonatomic, readonly) NSString *s_apiStopInfo;

@end


@interface ShuttleDataManager(Private)

-(void) sendRoutesToDelegates:(NSArray*)routes;
-(void) sendStopsToDelegates:(NSArray*)routes;
-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;
-(void) sendRouteToDelegates:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID;

@end


@implementation ShuttleDataManager
@synthesize shuttleRoutes = _shuttleRoutes;
@synthesize shuttleStops = _shuttleStops;
@synthesize shuttleRoutesByID = _shuttleRoutesByID;

@dynamic s_apiRoutes, s_apiStops, s_apiRouteInfo, s_apiStopInfo;

- (NSString *)s_apiRoutes {
    static NSString* s_apiRoutes = nil;
    if (!s_apiRoutes) {
        s_apiRoutes = [[NSString stringWithFormat:@"%@shuttles/?command=routes&compact=true", MITMobileWebAPIURLString] retain];
    }
    return s_apiRoutes;
}

- (NSString *)s_apiStops {
    static NSString* s_apiStops = nil;
    if (!s_apiStops) {
        s_apiStops = [[NSString stringWithFormat:@"%@shuttles/?command=stops", MITMobileWebAPIURLString] retain];
    }
    return s_apiStops;
}

- (NSString *)s_apiRouteInfo {
    static NSString* s_apiRouteInfo = nil;
    if (!s_apiRouteInfo) {
        s_apiRouteInfo = [[NSString stringWithFormat:@"%@shuttles/?command=routeInfo&id=%%@&full=true", MITMobileWebAPIURLString] retain];
    }
    return s_apiRouteInfo;
}

- (NSString *)s_apiStopInfo {
    static NSString* s_apiStopInfo = nil;
    if (!s_apiStopInfo) {
        s_apiStopInfo = [[NSString stringWithFormat:@"%@shuttles/?command=stopInfo&id=%%@", MITMobileWebAPIURLString] retain];
    }
    return s_apiStopInfo;
}

+ (ShuttleDataManager *)sharedDataManager {
    @synchronized(self) {
        if (s_dataManager == nil) {
            self = [[super allocWithZone:NULL] init]; 
			s_dataManager = self;
        }
    }
	
    return s_dataManager;
}

-(void) dealloc
{
	[_shuttleRoutes release];
	[_shuttleStops release];
	[_shuttleRoutesByID release];
	
	[_registeredDelegates release];
	
	[super dealloc];
}

-(void) requestRoutes
{
	PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
	postData.api = self.s_apiRoutes;
	postData.useNetworkActivityIndicator = YES;
	[postData getDataFromURL:[NSURL URLWithString:self.s_apiRoutes]];
}

-(void) requestStops
{
	PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
	postData.api = self.s_apiStops;
	postData.useNetworkActivityIndicator = YES;
	[postData getDataFromURL:[NSURL URLWithString:self.s_apiStops]];
}


-(void) requestStop:(NSString*)stopID
{
	NSString* urlString = [NSString stringWithFormat:self.s_apiStopInfo, stopID];
	PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
	postData.api = self.s_apiStopInfo;
	postData.userData = [NSDictionary dictionaryWithObject:stopID forKey:@"stopID"];
	postData.useNetworkActivityIndicator = YES;
	[postData getDataFromURL:[NSURL URLWithString:urlString]];
}

-(void) requestRoute:(NSString*)routeID
{
	NSString* urlString = [NSString stringWithFormat:self.s_apiRouteInfo, routeID];
	PostData* postData = [[[PostData alloc] initWithDelegate:self] autorelease];
	postData.api = self.s_apiRouteInfo;
	postData.userData = [NSDictionary dictionaryWithObject:routeID forKey:@"routeID"];
	postData.useNetworkActivityIndicator = YES;
	[postData getDataFromURL:[NSURL URLWithString:urlString]];
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

-(void) sendRouteToDelegates:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(routeInfoReceived:forRouteID:)]) {
			[delegate routeInfoReceived:shuttleRoute forRouteID:routeID];
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
}



#pragma mark PostDataDelegate

// data was received from the post data request. 
-(void) postData:(PostData*)postData receivedData:(NSData*) data
{
	NSString* results = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	if ([postData.api isEqualToString:(NSString*)self.s_apiRoutes]) {
		NSArray* routesArray = [results JSONValue];
		
		NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:routesArray.count];
		NSMutableDictionary* routesDict = [[NSMutableDictionary alloc] initWithCapacity:routesArray.count];
		
		for (NSDictionary* dictionary in routesArray) 
		{
			ShuttleRoute* route = [[[ShuttleRoute alloc] initWithDictionary:dictionary] autorelease];
			[array addObject:route];
			[routesDict setObject:route forKey:route.routeID];
		}
		
		@synchronized(self)
		{
			[_shuttleRoutes release];
			_shuttleRoutes = nil;
			_shuttleRoutes = array;
			
			[_shuttleRoutesByID release];
			_shuttleRoutesByID = nil;
			_shuttleRoutesByID = routesDict;
		}
		
		
		[self sendRoutesToDelegates:_shuttleRoutes];
		
		
	}
	else if([postData.api isEqualToString:(NSString*)self.s_apiStops])
	{
		NSArray* stopsArray = [results JSONValue];
		
		NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:stopsArray.count];
	
		for (NSDictionary* dictionary in stopsArray)
		{
			ShuttleStop* shuttleStop = [[[ShuttleStop alloc] initWithDictionary:dictionary] autorelease];
			[array addObject:shuttleStop];
		}
		
		@synchronized(self)
		{
			[_shuttleStops release];
			_shuttleStops = nil;
			_shuttleStops = array;
		}
		
		[self sendStopsToDelegates:_shuttleStops];
		
	}
	else if([postData.api isEqualToString:(NSString*) self.s_apiStopInfo])
	{
		NSDictionary* dict = [results JSONValue];
		NSArray* routesAtStop = [dict objectForKey:@"stops"];
		
		NSMutableArray* schedules = [NSMutableArray arrayWithCapacity:routesAtStop.count];
		
		NSString* stopID = [postData.userData objectForKey:@"stopID"];
		
		for (NSDictionary* routeAtStop in routesAtStop) 
		{
			RouteStopSchedule* routeStopSchedule =  [[[RouteStopSchedule alloc] initWithStopID:stopID andDictionary:routeAtStop] autorelease];
			[schedules addObject:routeStopSchedule];
		}
		
		[self sendStopToDelegates:schedules forStopID:[postData.userData objectForKey:@"stopID"]];
	}
	else if([postData.api isEqualToString:(NSString*) self.s_apiRouteInfo])
	{
		NSDictionary* routeInfo = [results JSONValue];
		ShuttleRoute* route = [[[ShuttleRoute alloc] initWithDictionary:routeInfo] autorelease];
		route.routeID = [postData.userData objectForKey:@"routeID"];
		[self sendRouteToDelegates:route forRouteID:route.routeID];
	}
}

// there was an error connecting to the specified URL. 
-(void) postData:(PostData*)postData error:(NSString*)error
{
	// there was an error. The delegates need to know that the request failed.
	// Send the delegates nil responses to signal a failure
	
	if ([postData.api isEqualToString:self.s_apiRoutes]) 
	{
		[self sendRoutesToDelegates:nil];
	}
	else if([postData.api isEqualToString:self.s_apiStops])
	{
		[self sendStopsToDelegates:nil];
	}
	else if([postData.api isEqualToString:self.s_apiStopInfo])
	{
		NSString* stopID = [postData.userData objectForKey:@"stopID"];
		[self sendStopToDelegates:nil forStopID:stopID];
	}
	else if([postData.api isEqualToString:self.s_apiRouteInfo])
	{
		NSString* routeID = [postData.userData objectForKey:@"routeID"];
		[self sendRouteToDelegates:nil forRouteID:routeID];
	}
	
}


@end
