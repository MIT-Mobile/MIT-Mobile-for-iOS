#import "ShuttleStop.h"
#import "CoreDataManager.h"
#import "ShuttleDataManager.h"
#import "ShuttleStopLocation.h"
#import "ShuttleRouteStop.h"
#import "ShuttleRoute.h"

@implementation ShuttleStop

// cached stop location properties
@dynamic title;
@dynamic stopID;
@dynamic latitude;
@dynamic longitude;
@dynamic routeStops;
@dynamic direction;

// cached stop-route properties
@dynamic routeID;
@dynamic path;
@dynamic order;
@synthesize routeStop = _routeStop;

// live stop-route properties
@synthesize nextScheduled = _nextScheduled;
@synthesize now = _now;
@synthesize upcoming = _upcoming;
//@synthesize predictions = _predictions;
@dynamic nextScheduledDate;
@dynamic predictions;

#pragma mark getters and setters

- (NSString *)title
{
	return _stopLocation.title;
}

- (void)setTitle:(NSString *)title
{
	_stopLocation.title = title;
}

- (NSString *)stopID
{
	return _stopLocation.stopID;
}

- (void)setStopID:(NSString *)stopID
{
	_stopLocation.stopID = stopID;
}

- (double)latitude
{
	return [_stopLocation.latitude doubleValue];
}

- (void)setLatitude:(double)latitude
{
	_stopLocation.latitude = [NSNumber numberWithDouble:latitude];
}

- (double)longitude
{
	return [_stopLocation.longitude doubleValue];
}

- (void)setLongitude:(double)longitude
{
	_stopLocation.longitude = [NSNumber numberWithDouble:longitude];
}

- (NSString *)direction
{
	return _stopLocation.direction;
}

- (void)setDirection:(NSString *)direction
{
	_stopLocation.direction = direction;
}

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

- (NSArray *)predictions
{
    if (self.nextScheduled == 0) {
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

- (void)setPredictions:(NSArray *)predictions
{
    [_predictions release];
    _predictions = [predictions retain];
}

#pragma mark initializers

- (id)initWithRouteStop:(ShuttleRouteStop *)routeStop
{
	self = [super init];
	if (self != nil) {
		self.routeStop = routeStop;
		_stopLocation = (ShuttleStopLocation *)self.routeStop.stopLocation;
		
	}
	return self;
}

- (id)initWithStopLocation:(ShuttleStopLocation *)stopLocation routeID:(NSString *)routeID
{
	self = [super init];
	if (self != nil) {
		_stopLocation = stopLocation;
		
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"(route.routeID LIKE %@) AND (stopLocation.stopID LIKE %@)", routeID, self.stopID];
		NSArray *routeStops = [CoreDataManager objectsForEntity:ShuttleRouteStopEntityName matchingPredicate:pred];
		
		if ([routeStops count] == 0) {
			//NSLog(@"inserting new routeStop for stop %@ on route %@", self.stopID, routeID);
			self.routeStop = (ShuttleRouteStop *)[CoreDataManager insertNewObjectForEntityForName:ShuttleRouteStopEntityName];
			self.routeStop.route = (NSManagedObject *)[ShuttleDataManager shuttleRouteWithID:routeID].cache;
			self.routeStop.stopLocation = _stopLocation;
            [CoreDataManager saveData];
		} else {
			//NSLog(@"fetching cached routeStop for stop %@ on route %@", self.stopID, routeID);
			self.routeStop = [routeStops lastObject];
		}
	}
	return self;
}

- (NSString *)description {
    return self.title;
}


- (NSDate *)nextScheduledDate {
    NSDate *result = nil;
    if (self.nextScheduled) {
        result = [NSDate dateWithTimeIntervalSince1970:self.nextScheduled];
    }
    return result;
}

- (void)updateInfo:(NSDictionary *)stopInfo
{
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
}

#pragma mark methods from RouteStopSchedule

-(NSInteger) predictionCount
{
	return self.predictions.count + 1;
}

-(NSDate*) dateForPredictionAtIndex:(int)index
{
	NSTimeInterval prediction = 0;
	
	if (index == 0) {
		prediction = self.nextScheduled;
	}
	else {
		prediction = [[self.predictions objectAtIndex:index - 1] doubleValue];
	}
	
	return [NSDate dateWithTimeIntervalSince1970:prediction];
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
