#import "ShuttleStop.h"


@implementation ShuttleStop

@synthesize title  = _title;
@synthesize nextScheduled = _nextScheduled;
@synthesize stopID = _stopID;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@synthesize routes = _routes;
@synthesize dataPopulated = _dataPopulated;
@synthesize direction = _direction;
@synthesize path = _path;
@synthesize upcoming = _upcoming;

- (id)initWithDictionary:(NSDictionary *)aDict {
    
	self = [super init];
	
    if (self != nil) {
        self.title = [aDict objectForKey:@"title"];
        self.nextScheduled = [[aDict objectForKey:@"nextScheduled"] integerValue];
		if (self.nextScheduled == 0) {
			self.nextScheduled = [[aDict objectForKey:@"next"] integerValue];
		}
		
		self.stopID = [aDict objectForKey:@"stop_id"];
		if (nil == self.stopID) {
			self.stopID = [aDict objectForKey:@"id"];
		}
		
		id num = [aDict objectForKey:@"lat"];
		if (nil != num && num != [NSNull null]) {
			self.latitude = [num doubleValue];
		}

		num = [aDict objectForKey:@"lon"];
		if(nil != num && num != [NSNull null])	
			self.longitude = [num doubleValue];
		
		self.routes = [aDict objectForKey:@"routes"];
		
		self.direction = [aDict objectForKey:@"direction"];
		self.path = [aDict objectForKey:@"path"];

		self.upcoming = [[aDict objectForKey:@"upcoming"] boolValue];
		
		self.dataPopulated = (self.routes != nil);
	
    }
    return self;
}

- (void)dealloc 
{    
	self.title = nil;
	self.stopID = nil;
	self.routes = nil;
	self.direction = nil;
	self.path = nil;
	
    [super dealloc];
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

@end
