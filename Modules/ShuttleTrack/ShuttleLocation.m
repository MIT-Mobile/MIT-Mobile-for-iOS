
#import "ShuttleLocation.h"


@implementation ShuttleLocation
@synthesize coordinate = _coordinate;
@synthesize secsSinceReport = _secsSinceReport;
@synthesize heading = _heading;


-(id) initWithDictionary:(NSDictionary*)dictionary
{
	self = [super init];
	if (self) {
		_coordinate.latitude = [[dictionary objectForKey:@"lat"] doubleValue];
		_coordinate.longitude = [[dictionary objectForKey:@"lon"] doubleValue];
		
		self.secsSinceReport = [[dictionary objectForKey:@"secsSinceReport"] intValue];
		self.heading = [[dictionary objectForKey:@"heading"] intValue];
	}
	
	return self;
}

// Title and subtitle for use by selection UI.
- (NSString *)title
{
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}

@end
