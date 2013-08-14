#import <Foundation/Foundation.h>
#import "MITMapRoute.h"
#import "ShuttleRouteCache.h"

@interface ShuttleRoute : NSObject <MITMapRoute> {
	
	// parsed path locations for the entire route. 
	NSMutableArray* _pathLocations;
	
	// annotaions for each shuttle stop 
	NSMutableArray* _stopAnnotations;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithCache:(ShuttleRouteCache *)cachedRoute;
- (void)updateInfo:(NSDictionary *)routeInfo;
- (NSString *)trackingStatus;
- (void)getStopsFromCache;
- (void)updatePath;

- (NSArray *)annotations;

@property (nonatomic, readwrite, strong) NSString *tag;
@property (nonatomic, readwrite, copy) NSArray* vehicleLocations;        // locations, if available of any vehicles on the route.

@property (nonatomic, strong, readonly) NSString *fullSummary;
@property (nonatomic, assign) BOOL gpsActive;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL liveStatusFailed;
@property (nonatomic, readwrite, strong) ShuttleRouteCache *cache;

@property (nonatomic, readwrite, strong) NSString *title;
@property (nonatomic, readwrite, strong) NSString *summary;
@property (nonatomic, strong) NSString *routeID;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, assign) BOOL isSafeRide;
@property (nonatomic, copy) NSMutableArray *stops;
@property (nonatomic, assign) NSInteger sortOrder;

@end
