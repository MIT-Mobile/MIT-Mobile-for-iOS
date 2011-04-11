/* ShuttleStop represents a stop along a specific route,
 * i.e. a unique route-stop combination.
 * Stop location information that does not vary by route is stored in the stopLocation property.
 * This is a retrofit interface that combines the old ShuttleStop with RouteStopSchedule
 */

#import <Foundation/Foundation.h>

@class ShuttleStopLocation;
@class ShuttleRouteStop;

@interface ShuttleStop : NSObject {
	
	NSTimeInterval _nextScheduled;
    NSTimeInterval _now;
	
	BOOL _upcoming;
	NSArray *_predictions;

	ShuttleStopLocation *_stopLocation;
	ShuttleRouteStop *_routeStop;
}

- (void)updateInfo:(NSDictionary *)stopInfo;

- (id)initWithRouteStop:(ShuttleRouteStop *)routeStop;
- (id)initWithStopLocation:(ShuttleStopLocation *)stopLocation routeID:(NSString *)routeID;

/// methods from RouteStopSchedule

// index 0 will be nextScheduled. Everything after that will come from predicitons array
-(NSDate*) dateForPredictionAtIndex:(int)index;

// number of available predictions. We add one for the next scheduled stop
-(NSInteger) predictionCount;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *stopID;
@property double latitude;
@property double longitude;
@property (nonatomic, retain) NSArray *routeStops;
@property (nonatomic, retain) NSString* direction;

@property (nonatomic, readonly) NSString* routeID;
@property (nonatomic, retain) NSArray* path;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, retain) ShuttleRouteStop *routeStop;

@property NSTimeInterval nextScheduled;
@property NSTimeInterval now;
@property (readonly) NSDate *nextScheduledDate;
@property (nonatomic, retain) NSArray* predictions;
@property BOOL upcoming;

@end
