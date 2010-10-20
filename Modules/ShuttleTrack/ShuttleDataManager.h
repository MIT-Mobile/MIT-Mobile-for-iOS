
#import <Foundation/Foundation.h>
#import "PostData.h"

@class ShuttleStop;
@class ShuttleRoute;

@protocol ShuttleDataManagerDelegate<NSObject>

// everything is optional. 
@optional

// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes;

// message sent when stops were received. If request failed, this is called with a nil stops array
-(void) stopsReceived:(NSArray*) routes;

// message sent when a shuttle stop is received. If request fails, this is called with nil 
-(void) stopInfoReceived:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;

// message sent when a shuttle route is received. If request fails, this is called with nil
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID;

@end


@interface ShuttleDataManager : NSObject <PostDataDelegate> {

	// cached shuttle routes.
	NSArray* _shuttleRoutes;
	
	// cached shuttle routes sorted by route ID
	NSDictionary* _shuttleRoutesByID;
	
	// cached shuttle stops. 
	NSArray* _shuttleStops;
	
	// registered delegates
	NSMutableArray* _registeredDelegates;
}

@property (readonly) NSArray* shuttleRoutes;
@property (readonly) NSDictionary* shuttleRoutesByID;

@property (readonly) NSArray* shuttleStops;

// get the signleton data manager
+(ShuttleDataManager*) sharedDataManager;

// delegate registration and unregistration
-(void) registerDelegate:(id<ShuttleDataManagerDelegate>)delegate;

-(void) unregisterDelegate:(id<ShuttleDataManagerDelegate>)delegate;

// request the routes from the server.
-(void) requestRoutes;

// request the stops
-(void) requestStops;

// request full information about a particular stop
-(void) requestStop:(NSString*)stopID;

// request full information about a particular route
-(void) requestRoute:(NSString*)routeID;

@end
