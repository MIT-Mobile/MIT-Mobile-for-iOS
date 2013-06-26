/* ShuttleStop represents a stop along a specific route,
 * i.e. a unique route-stop combination.
 * Stop location information that does not vary by route is stored in the stopLocation property.
 * This is a retrofit interface that combines the old ShuttleStop with RouteStopSchedule
 */

#import <Foundation/Foundation.h>
#import "ShuttleRoute.h"

@class ShuttleStopLocation2;
@class ShuttleRouteStop2;

@interface ShuttleStop : NSObject {
	
//	NSTimeInterval _nextScheduled;
//    NSTimeInterval _now;
	
//	BOOL _upcoming;
//	NSArray *_predictions;

	ShuttleStopLocation2 *_stopLocation;
	ShuttleRouteStop2 *_routeStop;
    
    
    // NEW API
    NSString *_stopID;
    NSString *_url;
    NSString *_title;
    double _latitude;
    double _longitude;
    NSArray *_predictions;
    NSArray *_schedule;
    
    NSTimeInterval _next;
    BOOL _upcoming;
    NSString *_routeID;  // needed if not enclosed by RouteItem
    NSTimeInterval _now; // reference time for predictions
}

- (void)updateInfo:(NSDictionary *)stopInfo;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithRouteStop:(ShuttleRouteStop2 *)routeStop;
- (id)initWithStopLocation:(ShuttleStopLocation2 *)stopLocation routeID:(NSString *)routeID;

/// methods from RouteStopSchedule

// index 0 will be nextScheduled. Everything after that will come from predicitons array
-(NSDate*) dateForPredictionAtIndex:(int)index;

// number of available predictions. We add one for the next scheduled stop
-(NSInteger) predictionCount;

//@property (nonatomic, retain) NSString *title;
//@property (nonatomic, retain) NSString *stopID;
//@property double latitude;
//@property double longitude;
@property (nonatomic, retain) NSArray *routeStops;              // not needed
//@property (nonatomic, retain) NSString* direction;

//@property (nonatomic, readonly) NSString* routeID;
@property (nonatomic, retain) NSArray* path;                    // not needed
@property (nonatomic, assign) NSInteger order;                  // not needed
@property (nonatomic, retain) ShuttleRouteStop2 *routeStop;

//@property NSTimeInterval nextScheduled;
//@property NSTimeInterval now;
//@property (readonly) NSDate *nextScheduledDate;
//@property (nonatomic, retain) NSArray* predictions;
//@property BOOL upcoming;


// NEW API
@property (nonatomic, retain) NSString *stopID;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *title;
@property double latitude;
@property double longitude;
@property (nonatomic, retain) NSArray *predictions;
@property (nonatomic, retain) NSArray *schedule;

@property NSTimeInterval next;
@property NSTimeInterval now;
@property BOOL upcoming;
@property (nonatomic, retain) NSString* routeID;
@property (nonatomic, retain) ShuttleRoute *routeName;


@end
