
#import "RouteStopSchedule.h"


@implementation RouteStopSchedule
@synthesize routeID = _routeID;
@synthesize stopID = _stopID;
@synthesize nextScheduled = _nextScheduled;
@synthesize predictions = _predictions;

-(id) initWithStopID:(NSString*) stopID andDictionary:(NSDictionary*)dictionary
{
	self = [super init];
	if (self) {
		self.stopID = stopID;
		self.routeID = [dictionary objectForKey:@"route_id"];
		
		NSNumber* next = [dictionary objectForKey:@"next"];
		if (nil == next)
			next = [dictionary objectForKey:@"nextScheduled"];
		
		self.nextScheduled = [next unsignedLongValue];
		
		NSArray* predictionsArr = [dictionary objectForKey:@"predictions"];
		
		NSMutableArray* predictions = [NSMutableArray arrayWithCapacity:predictionsArr.count];
		
		for (NSString* prediction in predictionsArr) 
		{
			NSInteger calculatedPrediction = self.nextScheduled + [prediction intValue];
			[predictions addObject:[NSNumber numberWithInt:calculatedPrediction]]; 
		}
		
		self.predictions = predictions;
	}
	
	return self;
}

-(NSInteger) predictionCount
{
	return self.predictions.count + 1;
}

-(NSDate*) dateForPredictionAtIndex:(int)index
{
	NSInteger prediction = 0;
	
	if (index == 0) {
		prediction = self.nextScheduled;
	}
	else {
		prediction = [[self.predictions objectAtIndex:index - 1] intValue];
	}

	return [NSDate dateWithTimeIntervalSince1970:prediction];
}

@end
