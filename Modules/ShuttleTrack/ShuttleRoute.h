#import <Foundation/Foundation.h>
#import "MITMapRoute.h"
#import "ShuttleRouteCache2.h"
#import "ShuttleRoutePath.h"

#define DAYTIME_SHUTTLES        @"Daytime Shuttles"
#define NIGHTTIME_SHUTTLES      @"Nighttime Saferide Shuttles"


@interface ShuttleRoute : NSObject <MITMapRoute> {
    NSString *_tag;
    BOOL _gpsActive;
    BOOL _isRunning;
	BOOL _liveStatusFailed;
	ShuttleRouteCache2 *_cache;

//    NSMutableArray *_stops;
	
	// parsed path locations for the entire route. 
	NSMutableArray* _pathLocations;
	
	// annotaions for each shuttle stop 
	NSMutableArray* _stopAnnotations;
	
	// locations, if available of any vehicles on the route. 
	NSMutableArray* _vehicleLocations;
    
    
    // NEW API
    NSString *_routeID;
	NSString *_url;
	NSString *_title;
	NSString *_description;
	NSString *_group;
	BOOL _active;
	BOOL _predictable;
	int _interval;
	
	NSMutableArray *_stops;
	NSArray *_vehicles;
	ShuttleRoutePath *_path;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithCache:(ShuttleRouteCache2 *)cachedRoute;
- (void)updateInfo:(NSDictionary *)routeInfo;
- (NSString *)trackingStatus;
- (void)getStopsFromCache;
- (void)updatePath;

@property (readwrite, retain) NSString *tag;
@property (readwrite, retain) NSMutableArray* vehicleLocations;

@property (readonly) NSString *fullSummary;
@property (assign) BOOL gpsActive;
@property (assign) BOOL isRunning;
@property (assign) BOOL liveStatusFailed;
@property (readwrite, retain) ShuttleRouteCache2 *cache;

//@property (readwrite, retain) NSString *title;
@property (readwrite, retain) NSString *summary;
//@property (nonatomic, retain) NSString *routeID;
//@property (assign) NSInteger interval;
//@property (readwrite, retain) NSMutableArray *stops;
@property (assign) NSInteger sortOrder;


// NEW API
@property (readwrite, retain) NSString *routeID;
@property (readwrite, retain) NSString *url;
@property (readwrite, retain) NSString *title;
@property (readwrite, retain) NSString *description;
@property (readwrite, retain) NSString *group;
@property (assign) BOOL active;
@property (assign) BOOL predictable;
@property (assign) int interval;

@property (readwrite, retain) NSMutableArray *stops;
@property (readwrite, retain) NSArray *vehicles;
@property (readwrite, retain) ShuttleRoutePath *path;

@end
