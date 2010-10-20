
#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"


@class ShuttleStop;
@class ShuttleRoute;
@class RouteStopSchedule;

@protocol ShuttleSubscriptionDelegate <NSObject>

- (void) subscriptionSucceededWithObject: (id)object;
- (void) subscriptionFailedWithObject: (id)object;

@end


@interface ShuttleSubscriptionManager : NSObject {
	NSDictionary *loadingSubscription;
}

+ (void) subscribeForRoute: (ShuttleRoute *)route atStop: (ShuttleStop *)stop scheduleTime: (NSDate *)time delegate: (id<ShuttleSubscriptionDelegate>)delegate object: (id)object;

+ (void) unsubscribeForRoute: (ShuttleRoute *)route atStop: (ShuttleStop *)stop delegate: (id<ShuttleSubscriptionDelegate>)delegate object: (id)object;

+ (BOOL) hasSubscription: (ShuttleRoute *)route atStop: (ShuttleStop *)stop scheduleTime: (NSDate *)time;

+ (void) addSubscriptionForRouteId: (NSString *)routeId atStopId: (NSString *)stopId startTime: (NSDate *)startTime endTime: (NSDate *)endTime;

+ (void) removeSubscriptionForRouteId: (NSString *)routeId atStopId: (NSString *)stopId;

+ (void) pruneSubscriptions;

@end

@interface SubscribeRequest : NSObject<JSONLoadedDelegate>
{
	id object;
	id<ShuttleSubscriptionDelegate> delegate;
	ShuttleRoute *route;
	ShuttleStop *stop;
}

- (id) initWithDelegate: (id<ShuttleSubscriptionDelegate>)delegate route: (ShuttleRoute *)route stop: (ShuttleStop *)stop object: (id)object ;

@end

@interface UnsubscribeRequest : NSObject<JSONLoadedDelegate>
{
	id object;
	id<ShuttleSubscriptionDelegate> delegate;
	ShuttleRoute *route;
	ShuttleStop *stop;
}

- (id) initWithDelegate: (id<ShuttleSubscriptionDelegate>)delegate route: (ShuttleRoute *)route stop: (ShuttleStop *)stop object: (id)object ;

@end
