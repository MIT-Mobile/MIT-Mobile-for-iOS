
#import <Foundation/Foundation.h>


@interface RouteStopSchedule : NSObject 
{
	NSString* _routeID;
	NSString* _stopID;
	NSUInteger _nextScheduled;
	NSArray* _predictions;
}

@property (nonatomic, retain) NSString* routeID;
@property (nonatomic, retain) NSString* stopID;
@property NSUInteger nextScheduled;
@property (nonatomic, retain) NSArray* predictions;

-(id) initWithStopID:(NSString*) stopID andDictionary:(NSDictionary*)dictionary;

// index 0 will be nextScheduled. Everything after that will come from predicitons array
-(NSDate*) dateForPredictionAtIndex:(int)index;

// number of available predictions. We add one for the next scheduled stop
-(NSInteger) predictionCount;
@end
