#import "CalendarMapView.h"
#import "MITCalendarEvent.h"
#import "CalendarEventMapAnnotation.h"
#import "CoreLocation+MITAdditions.h"

@implementation CalendarMapView
{
    NSArray *_events;
}

- (NSArray *)events
{
	return _events;
}

/*
 * while setting events
 * create map annotations for all events that we can map
 * and get min/max lat/lon for map region
 */
- (void)setEvents:(NSArray *)events
{
    [self removeAllAnnotations:YES];
    
	_events = events;
    
    if ([_events count])
    {
        NSMutableArray *mappedEvents = [NSMutableArray array];
        for (MITCalendarEvent *event in [events reverseObjectEnumerator]) {
            if ([event hasCoords]) {
                [mappedEvents addObject:[[CalendarEventMapAnnotation alloc] initWithEvent:event]];
            }
        }
        
        [self addAnnotations:mappedEvents];
        MKCoordinateRegion region = [self regionForAnnotations:mappedEvents];
        self.region = region;

    } else {
        
        [self setRegion:MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN)];
    }
    
}

@end
