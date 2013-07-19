#import "ShuttleStop.h"
#import "CoreDataManager.h"
#import "ShuttleDataManager.h"
#import "ShuttleStopLocation2.h"
#import "ShuttleRouteStop2.h"
#import "ShuttleRoute.h"
#import "ShuttlePrediction.h"

@implementation ShuttleStop

// cached stop location properties
//@dynamic stopID;
@synthesize stopID = _stopID;
@synthesize url = _url;
//@dynamic title;   // check when use cache
@synthesize title = _title;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

// cached stop-route properties
@synthesize routeID = _routeID;

// live stop-route properties
@synthesize next = _next;
@synthesize now = _now;
@synthesize upcoming = _upcoming;
@synthesize predictions = _predictions;
@synthesize schedule = _schedule;

@synthesize routeStop = _routeStop;
@synthesize routeName;


#pragma mark getters and setters

/*
- (NSString *)stopID
{
    return _stopID;
}

- (void)setStopID:(NSString *)stopID
{
    _stopID = stopID;
}

- (double)latitude
{
    return _latitude;
}

- (void)setLatitude:(double)latitude
{
    _latitude = latitude;
}

- (double)longitude
{
    return _longitude;
}

- (void)setLongitude:(double)longitude
{
    _longitude = longitude;
}

- (NSString *)url {
    return _url;
}

- (void)setUrl:(NSString *)url {
    _url = url;
}

- (NSString *)routeID {
    return _routeID;
}

- (void)setRouteID:(NSString *)routeID {
    _routeID = routeID;
}
*/
 
- (NSString *)direction
{
    return @"";
//	return _stopLocation.direction;
}

- (void)setDirection:(NSString *)direction
{
//	_stopLocation.direction = direction;
}

/*
- (NSArray *)routeStops
{
	return [_stopLocation.routeStops allObjects];
}

- (void)setRouteStops:(NSArray *)routeStops
{
	_stopLocation.routeStops = [NSSet setWithArray:routeStops];
}

- (NSString *)routeID
{
	return [self.routeStop routeID];
}

- (NSInteger)order
{
	return [self.routeStop.order intValue];
}

- (void)setOrder:(NSInteger)order
{
	self.routeStop.order = [NSNumber numberWithInt:order];
}

- (NSArray *)path
{
	NSData *pathData = self.routeStop.path;
	return [NSKeyedUnarchiver unarchiveObjectWithData:pathData];
}

- (void)setPath:(NSArray *)path
{
	NSData *pathData = [NSKeyedArchiver archivedDataWithRootObject:path];
	self.routeStop.path = pathData;
}
 */

/*
- (NSArray *)predictions
{
    if (self.next == 0) {
        return [NSArray array];
    } else {
        NSMutableArray *absPredictions = [NSMutableArray arrayWithCapacity:_predictions.count];
        for (NSString *prediction in _predictions) {
            NSTimeInterval predictionTime = [prediction doubleValue] + self.now;
            [absPredictions addObject:[NSNumber numberWithDouble:predictionTime]];
        }
        return [NSArray arrayWithArray:absPredictions];
    }
}
*/

#pragma mark initializers

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
	if (self != nil) {
		[self updateInfo:dict];
	}
	return self;
}

- (id)initWithRouteStop:(ShuttleRouteStop2 *)routeStop
{
	self = [super init];
	if (self != nil) {
		self.routeStop = routeStop;
//		_stopLocation = (ShuttleStopLocation2 *)self.routeStop.stopLocation;
        _stopLocation = (ShuttleStopLocation2 *)routeStop.stopLocation;
        [self initWithStopLocation:_stopLocation routeID:self.routeStop.routeID];
	}
	return self;
}


- (id)initWithStopLocation:(ShuttleStopLocation2 *)stopLocation routeID:(NSString *)routeID
{
	self = [super init];
	if (self != nil) {
		_stopLocation = stopLocation;
		
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"(route.routeID LIKE %@) AND (stopLocation.stopID LIKE %@)", routeID, stopLocation.stopID];
        NSArray *routeStops = [CoreDataManager objectsForEntity:ShuttleRouteStopEntityName matchingPredicate:pred];
		
		if ([routeStops count] == 0) {
			
			self.routeStop = (ShuttleRouteStop2 *)[CoreDataManager insertNewObjectForEntityForName:ShuttleRouteStopEntityName];
			self.routeStop.route = (NSManagedObject *)[ShuttleDataManager shuttleRouteWithID:routeID].cache;
			self.routeStop.stopLocation = _stopLocation;
            [CoreDataManager saveData];
		} else {
			
			self.routeStop = [routeStops lastObject];
            self.stopID = stopLocation.stopID;
            self.title = stopLocation.title;
            self.latitude = [[stopLocation latitude] doubleValue];
            self.longitude = [[stopLocation longitude] doubleValue];
		}
	}
	return self;
}


- (NSString *)description {
    return self.title;
}


- (NSDate *)nextScheduledDate {
    NSDate *result = nil;
//    if (self.nextScheduled) {
//        result = [NSDate dateWithTimeIntervalSince1970:self.nextScheduled];
//    }
    return result;
}

- (void) setPredictions:(NSArray *)predictions withPredictable:(BOOL)isPredictable
{
    _predictions = predictions;
    
    long now = [[NSDate date] timeIntervalSince1970];
    
    if ([predictions count] == 0)
    {
        return;
    }
    
    if(isPredictable)
    {
        for (ShuttlePrediction *prediction in predictions) {
            if ([prediction timestamp] / 1000 > now) {
                _next = prediction.timestamp / 1000;
            break;
            }
        }
    }
}

- (void) setSchedule:(NSArray *)schedule withPredictable:(BOOL)isPredictable
{
    _schedule = schedule;
    
    long now = [[NSDate date] timeIntervalSince1970];
    
    if ([schedule count] == 0)
    {
        return;
    }
    
    if(!isPredictable)
    {
        int index = -1;
        long diff = now;
        
        for (int i = 0; i < [schedule count]; i++) {
            long value = [[schedule objectAtIndex:i] longValue];
            if (value > now && (value - now < diff)) {
                diff = value - now;
                index = i;
            }
        }        
        _next = [[schedule objectAtIndex:(index != -1 ? index : 0) ] longValue ];
    }
}

- (void)updateInfo:(NSDictionary *)stopInfo
{
    self.stopID = [stopInfo objectForKey:@"id"];
    self.url = [stopInfo objectForKey:@"url"];
    self.title = [stopInfo objectForKey:@"title"];
    self.latitude = [[stopInfo objectForKey:@"lat"] doubleValue];
    self.longitude = [[stopInfo objectForKey:@"lon"] doubleValue];
    
    int startPos = [self.url rangeOfString:@"/routes/"].location + @"/routes/".length;
    int endPos = self.url.length - self.stopID.length - @"/stops/".length;
    NSString *routeID = [self.url substringWithRange:NSMakeRange(startPos, endPos - startPos)];
    self.routeID = routeID;
    
    // Get predictions
    NSArray *predictions = [stopInfo objectForKey:@"predictions"];
    if (predictions)
    {
        NSMutableArray *predictionArray = [[NSMutableArray alloc] init];
        
        for (int i=0; i<[predictions count]; i++){
            NSDictionary *jPrediction = [predictions objectAtIndex:i];
            ShuttlePrediction *prediction = [[ShuttlePrediction alloc]initWithDictionary:jPrediction];
            [predictionArray addObject:prediction];
        }
        [self setPredictions:predictionArray withPredictable:[predictionArray count] > 0];
    }
    
    
    // Get schedule
    NSArray *schedule = [stopInfo objectForKey:@"schedule"];
    [self setSchedule:schedule withPredictable:[self.predictions count] > 0];
    
    
    /*
	NSString *property = nil;
	if ((property = [stopInfo objectForKey:@"title"]) != nil) {
		self.title = property;
    }
	if ((property = [stopInfo objectForKey:@"direction"]) != nil) {
        self.direction = property;
    }
	
	NSNumber *num = nil;
	if ((num = [stopInfo objectForKey:@"lon"]) != nil) {
        self.longitude = [num doubleValue];
    }
	if ((num = [stopInfo objectForKey:@"lat"]) != nil) {
		self.latitude = [num doubleValue];
    }
	self.upcoming = ([stopInfo objectForKey:@"upcoming"] != nil); // upcoming only appears if it's true
	
	if ((num = [stopInfo objectForKey:@"next"]) != nil ||
		(num = [stopInfo objectForKey:@"nextScheduled"]) != nil) {
		self.nextScheduled = [num doubleValue];
    }

	NSArray *array = nil;
	if ((array = [stopInfo objectForKey:@"path"]) != nil) {
		self.path = array;
    } else {
        self.path = [NSArray array];
    }
    if ((array = [stopInfo objectForKey:@"predictions"]) != nil) {
        self.predictions = array;
    }
     */
}

#pragma mark methods from RouteStopSchedule

-(NSInteger) predictionCount
{
    return [self.predictions count] == 0 ? 1 : self.predictions.count;
}

-(NSDate*) dateForPredictionAtIndex:(int)index
{
	ShuttlePrediction *prediction;
	
	if (index == 0) {
        return [NSDate dateWithTimeIntervalSince1970:self.next];
	}
	else {
        prediction = [self.predictions objectAtIndex:index];
	}
	
	return [NSDate dateWithTimeIntervalSince1970:prediction.timestamp / 1000];
}

#pragma mark -

- (void)dealloc 
{   
	_stopLocation = nil;
	self.routeStop = nil;

	[_predictions release];
	
    [super dealloc];
}

@end
