
#import "ShuttleSubscriptionManager.h"
#import "ShuttleStop.h"
#import "ShuttleRoute.h"
#import "MITDeviceRegistration.h"

@implementation ShuttleSubscriptionManager
	
+ (void) subscribeForRoute: (ShuttleRoute *)route atStop: (ShuttleStop *)stop scheduleTime: (NSDate *)time delegate: (id<ShuttleSubscriptionDelegate>)delegate object: (id)object {
	NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
	[parameters setObject:@"subscribe" forKey:@"command"];
	[parameters setObject:route.routeID forKey:@"route"];
	[parameters setObject:stop.stopID forKey:@"stop"];
	
	NSInteger unixtime_int = round([time timeIntervalSince1970]);
	NSString *unixtime_string = [NSString stringWithFormat:@"%i", unixtime_int];	
	[parameters setObject:unixtime_string forKey:@"time"];	
	
	MITMobileWebAPI *mobileWebApi = [MITMobileWebAPI jsonLoadedDelegate:
		[[[SubscribeRequest alloc] initWithDelegate:delegate route:route stop:stop object:object] autorelease]];

	[mobileWebApi requestObject:parameters pathExtension:@"shuttles"];
}

+ (void) unsubscribeForRoute: (ShuttleRoute *)route atStop: (ShuttleStop *)stop delegate: (id<ShuttleSubscriptionDelegate>)delegate object: (id)object {
	NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
	[parameters setObject:@"unsubscribe" forKey:@"command"];
	[parameters setObject:route.routeID forKey:@"route"];
	[parameters setObject:stop.stopID forKey:@"stop"];
	
	MITMobileWebAPI *mobileWebApi = [MITMobileWebAPI jsonLoadedDelegate:
		[[[UnsubscribeRequest alloc] initWithDelegate:delegate route:route stop:stop object:object] autorelease]];
	
	[mobileWebApi requestObject:parameters pathExtension:@"shuttles"];
}
	
+ (BOOL) hasSubscription: (ShuttleRoute *)route atStop: (ShuttleStop *)stop scheduleTime: (NSDate *)time {
	[self pruneSubscriptions];
	
	NSDictionary *savedSubscriptions = [[NSUserDefaults standardUserDefaults] objectForKey:ShuttleSubscriptionsKey];
	
	NSArray *subscriptionTimeWindow = [[savedSubscriptions objectForKey:route.routeID] objectForKey:stop.stopID];
	if(subscriptionTimeWindow) {
		NSDate *startTime = [subscriptionTimeWindow objectAtIndex:0];
		NSDate *endTime = [subscriptionTimeWindow objectAtIndex:1];
		
		// check if time is within time interval
		return ([time timeIntervalSinceDate:startTime] > 0) && ([time timeIntervalSinceDate:endTime] < 0);
	}
	return NO;
}
			
+ (void) pruneSubscriptions {		
	NSDictionary *subscriptions = [[NSUserDefaults standardUserDefaults] objectForKey:ShuttleSubscriptionsKey];
	NSMutableDictionary *mutableSubscriptions = [NSMutableDictionary dictionaryWithDictionary:subscriptions];
	for(NSString *routeID in [mutableSubscriptions allKeys]) {
		NSMutableDictionary *mutableRouteStopsDictionary = [NSMutableDictionary dictionaryWithDictionary:[mutableSubscriptions objectForKey:routeID]];
		for(NSString *aStopKey in [mutableRouteStopsDictionary allKeys]) {
			NSDate *endTime = [((NSArray *)[mutableRouteStopsDictionary objectForKey:aStopKey]) objectAtIndex:1];
			if([endTime timeIntervalSinceNow] < 0) {
				// this subscription is in the past it needs to be cleared
				[mutableRouteStopsDictionary removeObjectForKey:aStopKey];
			}
		}
		
		// check if the subscriptions for route are now empty
		// if not empty, update main dictionary, otherwise delete this route dictionary
		if([[mutableRouteStopsDictionary allKeys] count]) {
			[mutableSubscriptions setObject:mutableRouteStopsDictionary forKey:routeID];
		} else {
			[mutableSubscriptions removeObjectForKey:routeID];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:mutableSubscriptions forKey:ShuttleSubscriptionsKey];
}
	

+ (void) addSubscriptionForRouteId: (NSString *)routeId atStopId: (NSString *)stopId startTime: (NSDate *)startTime endTime: (NSDate *)endTime {
	NSDictionary *subscriptions = [[NSUserDefaults standardUserDefaults] objectForKey:ShuttleSubscriptionsKey];
	
	NSMutableDictionary *mutableSubscriptions = [NSMutableDictionary dictionaryWithDictionary:subscriptions];
	NSMutableDictionary *routeSubscriptions = [mutableSubscriptions objectForKey:routeId];
	
	if(!routeSubscriptions) {
		routeSubscriptions = [NSMutableDictionary dictionary];
	} else {
		routeSubscriptions = [NSMutableDictionary dictionaryWithDictionary:routeSubscriptions];
	}
	[mutableSubscriptions setObject:routeSubscriptions forKey:routeId];
	
	[routeSubscriptions setObject:[NSArray arrayWithObjects:startTime, endTime, nil] forKey:stopId];
	
	[[NSUserDefaults standardUserDefaults] setObject:mutableSubscriptions forKey:ShuttleSubscriptionsKey];
}

+ (void) removeSubscriptionForRouteId: (NSString *)routeId atStopId: (NSString *)stopId {
	NSDictionary *subscriptions = [[NSUserDefaults standardUserDefaults] objectForKey:ShuttleSubscriptionsKey];

	NSMutableDictionary *mutableSubscriptions = [NSMutableDictionary dictionaryWithDictionary:subscriptions];
	NSMutableDictionary *routeSubscriptions = [mutableSubscriptions objectForKey:routeId];

	if(!routeSubscriptions) {
		// no subscription found
		return;
	}

	routeSubscriptions = [NSMutableDictionary dictionaryWithDictionary:routeSubscriptions];
	[mutableSubscriptions setObject:routeSubscriptions forKey:routeId];
	[routeSubscriptions removeObjectForKey:stopId];

	[[NSUserDefaults standardUserDefaults] setObject:mutableSubscriptions forKey:ShuttleSubscriptionsKey];
}
			
@end

@implementation SubscribeRequest

- (id) initWithDelegate: (id<ShuttleSubscriptionDelegate>)theDelegate route: (ShuttleRoute *)theRoute stop: (ShuttleStop *)theStop object: (id)theObject {
	if(self = [super init]) {
		delegate = [theDelegate retain];
		object = [theObject retain];
		route = [theRoute retain];
		stop = [theStop retain];
	}
	return self;
}

- (void) dealloc {
	[delegate release];
	[object release];
	[route release];
	[stop release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)jsonObject {
	NSDictionary *jsonDict = jsonObject;
	
	if([jsonDict objectForKey:@"success"]) {		
		NSNumber *startTimeNumber = [jsonDict objectForKey:@"start_time"];
		NSNumber *endTimeNumber = [jsonDict objectForKey:@"expire_time"];
		
		NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:[startTimeNumber doubleValue]];
		NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:[endTimeNumber doubleValue]];
		
		[ShuttleSubscriptionManager addSubscriptionForRouteId:route.routeID atStopId:stop.stopID startTime:startTime endTime:endTime];
		[delegate subscriptionSucceededWithObject:object];
	} else {
		[delegate subscriptionFailedWithObject:object];
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[delegate subscriptionFailedWithObject:object];
}

@end

@implementation UnsubscribeRequest

- (id) initWithDelegate: (id<ShuttleSubscriptionDelegate>)theDelegate route: (ShuttleRoute *)theRoute stop: (ShuttleStop *)theStop object: (id)theObject {
	if(self = [super init]) {
		delegate = [theDelegate retain];
		object = [theObject retain];
		route = [theRoute retain];
		stop = [theStop retain];
	}
	return self;
}

- (void) dealloc {
	[delegate release];
	[object release];
	[route release];
	[stop release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)jsonObject {
	[ShuttleSubscriptionManager removeSubscriptionForRouteId:route.routeID atStopId:stop.stopID];
	[delegate subscriptionSucceededWithObject:object];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[delegate subscriptionFailedWithObject:object];
}

@end










