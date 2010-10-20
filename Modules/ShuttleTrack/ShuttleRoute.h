#import <Foundation/Foundation.h>
#import "MITMapRoute.h"

@interface ShuttleRoute : NSObject <MITMapRoute> {
    NSString *_tag;
    NSString *_title;
    NSString *_summary;
	NSString *_routeID;
    BOOL _gpsActive;
    NSInteger _interval;
    BOOL _isRunning;
    BOOL _isSafeRide;
    NSMutableArray *_stops;
	
	// parsed path locations for the entire route. 
	NSMutableArray* _pathLocations;
	
	// annotaions for each shuttle stop 
	NSMutableArray* _stopAnnotations;
	
	// locations, if available of any vehicles on the route. 
	NSArray* _vehicleLocations;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)setStopsWithArray:(NSArray *)anArray;

@property (readwrite, retain) NSString *tag;
@property (readwrite, retain) NSString *title;
@property (readwrite, retain) NSString *summary;
@property (nonatomic, retain) NSString *routeID;
@property (readwrite, retain) NSArray* vehicleLocations;

@property (readonly) NSString *fullSummary;
@property (assign) BOOL gpsActive;
@property (assign) NSInteger interval;
@property (assign) BOOL isRunning;
@property (assign) BOOL isSafeRide;
@property (readwrite, retain) NSMutableArray *stops;


@end
