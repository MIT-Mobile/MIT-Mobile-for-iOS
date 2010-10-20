#import "ShuttleRoute.h"
#import "ShuttleStop.h" 
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleLocation.h"

@implementation ShuttleRoute

@synthesize tag = _tag;
@synthesize title = _title;
@synthesize summary = _summary;
@synthesize gpsActive = _gpsActive;
@synthesize interval = _interval;
@synthesize isRunning = _isRunning;
@synthesize isSafeRide = _isSafeRide;
@synthesize stops = _stops;
@synthesize routeID = _routeID;
@synthesize vehicleLocations = _vehicleLocations;

@dynamic fullSummary;

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self != nil) {
        self.tag = [dict objectForKey:@"tag"];
        self.title = [dict objectForKey:@"title"];
        self.summary = [dict objectForKey:@"summary"];
		self.routeID = [dict objectForKey:@"route_id"];
        self.gpsActive = [[dict objectForKey:@"gpsActive"] boolValue];
        self.interval = [[dict objectForKey:@"interval"] integerValue];
        self.isRunning = [[dict objectForKey:@"isRunning"] boolValue];
        self.isSafeRide = [[dict objectForKey:@"isSafeRide"] boolValue];
		
		// create the stops
		NSArray* stops = [dict objectForKey:@"stops"];
		NSMutableArray* formattedStops = [NSMutableArray arrayWithCapacity:stops.count];
		_stopAnnotations = [[NSMutableArray alloc] initWithCapacity:stops.count];
		_pathLocations = [[NSMutableArray alloc] init];
		
		for (NSDictionary* stop in stops)
		{
			ShuttleStop* formattedStop = [[[ShuttleStop alloc] initWithDictionary:stop] autorelease];
			[formattedStops addObject:formattedStop];
			
			// create an annotation for this stop. 
			ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:formattedStop] autorelease];
			[_stopAnnotations addObject:annotation];
			
			for(NSDictionary* pathComponent in formattedStop.path)
			{
				CLLocation* location = [[[CLLocation alloc] initWithLatitude:[[pathComponent objectForKey:@"lat"] doubleValue]
																   longitude:[[pathComponent objectForKey:@"lon"] doubleValue]
										 ] autorelease];

				[_pathLocations addObject:location];
			}
		}
		
		self.stops = formattedStops;
		
		NSArray* vehicleLocations = [dict objectForKey:@"vehicleLocations"];
		if (nil != vehicleLocations && [NSNull null] != (id)vehicleLocations) 
		{
			NSMutableArray* formattedVehicleLocations = [NSMutableArray arrayWithCapacity:vehicleLocations.count];
			for(NSDictionary* dictionary in vehicleLocations)
			{
				ShuttleLocation* shuttleLocation = [[[ShuttleLocation alloc] initWithDictionary:dictionary] autorelease];
				[formattedVehicleLocations addObject:shuttleLocation];
			}
			self.vehicleLocations = formattedVehicleLocations;
			
		}
		
    }
    return self;
}

-(void) dealloc
{
	self.tag = nil;
	self.title = nil;
	self.summary = nil;
	self.routeID = nil;
	self.stops = nil;
	self.vehicleLocations = nil;
	
	[_pathLocations release];
	[_stopAnnotations release];
	
	[super dealloc];
}
- (NSString *)fullSummary 
{
	NSString* summaryString = [NSString stringWithFormat:@"Route loop repeats every %ld minutes.", self.interval];
	if (nil != self.summary) 
	{
		summaryString = [NSString stringWithFormat:@"%@ %@", self.summary, summaryString];
	}
	
	if(self.vehicleLocations && self.vehicleLocations.count > 0)
	{
		summaryString = [NSString stringWithFormat:@"Real time bus tracking online.\n%@", summaryString];
	} else {
		summaryString = [NSString stringWithFormat:@"Tracking offline. Following schedule.\n%@", summaryString];
	}
	
    return summaryString;
}

- (void)setStopsWithArray:(NSArray *)anArray {
    self.stops = [NSMutableArray arrayWithCapacity:[anArray count]];
    
}

#pragma mark -
#pragma mark Useful Overrides

- (NSString *)description {
    return self.title;
}

// override -isEqual: and -hash so that any ShuttleRoute objects with the same self.tag will be considered the same. Useful for finding objects in collections like -[NSArray indexOfObject:].
- (BOOL)isEqual:(id)anObject {
    ShuttleRoute *otherRoute = nil;
    if (anObject && [anObject isKindOfClass:[ShuttleRoute class]]) {
        otherRoute = (ShuttleRoute *)anObject;
    }
    return (otherRoute && [self.tag isEqual:otherRoute.tag]);
}

- (NSUInteger)hash {
    return [self.tag hash];
}

- (NSComparisonResult)compare:(ShuttleRoute *)aRoute {
    return [self.title compare:aRoute.title];
}

#pragma mark MITMapRoute

// array of CLLocations making up the path of this route
-(NSArray*) pathLocations
{
	return _pathLocations;
}

// array of MKAnnotations that are to be included with this route
-(NSArray*) annotations
{
	return _stopAnnotations;
}

// color of the route line to be rendered
-(UIColor*) lineColor
{
	return [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75];
}

// width of the route line to be rendered
-(CGFloat) lineWidth
{
	return 3.0;
}

@end
