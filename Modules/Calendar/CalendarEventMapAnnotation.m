#import "CalendarEventMapAnnotation.h"
#import "MITCalendarEvent.h"

@implementation CalendarEventMapAnnotation

@synthesize event;

- (id)initWithEvent:(MITCalendarEvent *)anEvent {
    self = [super init];
    if (self) {
        event = anEvent;
    }
    return self;
}

-(CLLocationCoordinate2D) coordinate
{
	CLLocationCoordinate2D coordinate;
    
	coordinate.latitude = [self.event.latitude doubleValue];
	coordinate.longitude = [self.event.longitude doubleValue];
	
	return coordinate;
}

- (NSInteger)eventID
{
	return [self.event.eventID intValue];
}

- (NSString *)subtitle
{
	return [self.event subtitle];
}

- (NSString *)title
{
	return self.event.title;
}

- (void)dealloc
{
	event = nil;
	[super dealloc];
}


@end
