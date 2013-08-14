
#import "ShuttleLocation.h"

@interface ShuttleLocation ()

@property CLLocationCoordinate2D coordinate;

@end

@implementation ShuttleLocation

-(id) initWithDictionary:(NSDictionary*)dictionary
{
	self = [super init];
	if (self) {
		_coordinate.latitude = [dictionary[@"lat"] doubleValue];
		_coordinate.longitude = [dictionary[@"lon"] doubleValue];
		
		self.secsSinceReport = [dictionary[@"secsSinceReport"] intValue];
		self.heading = [dictionary[@"heading"] intValue];
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
