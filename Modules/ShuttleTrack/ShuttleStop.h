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

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *stopID;
@property double latitude;
@property double longitude;
@property (nonatomic, copy) NSArray *routeStops;
@property (nonatomic, strong) NSString* direction;

@property (nonatomic, strong, readonly) NSString* routeID;
@property (nonatomic, copy) NSArray* path;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, strong) ShuttleRouteStop *routeStop;

@property NSTimeInterval nextScheduled;
@property NSTimeInterval now;
@property (readonly) NSDate *nextScheduledDate;
@property (nonatomic, copy) NSArray* predictions;
@property BOOL upcoming;

@end
