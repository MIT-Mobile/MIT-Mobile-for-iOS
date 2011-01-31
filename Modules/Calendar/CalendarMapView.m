#import "CalendarMapView.h"
#import "MITCalendarEvent.h"
#import "CalendarEventMapAnnotation.h"

@implementation CalendarMapView

@dynamic events;

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
    
    [_events release];
	_events = [events retain];
    
    if ([_events count]) {
        
        double minLat = 90;
        double maxLat = -90;
        double minLon = 180;
        double maxLon = -180;
        
        for (MITCalendarEvent *event in [events reverseObjectEnumerator]) {
            if ([event hasCoords]) {
                CalendarEventMapAnnotation *annotation = [[[CalendarEventMapAnnotation alloc] initWithEvent:event] autorelease];
                [self addAnnotation:annotation];
				
                double eventLat = [event.latitude doubleValue];
                double eventLon = [event.longitude doubleValue];
                if (eventLat < minLat) {
                    minLat = eventLat;
                }
                if (eventLat > maxLat) {
                    maxLat = eventLat;
                }
                if(eventLon < minLon) {
                    minLon = eventLon;
                }
                if (eventLon > maxLon) {
                    maxLon = eventLon;
                }
            }
        }
        
        if (maxLon == -180)
            return;
        
        CLLocationCoordinate2D center;
        center.latitude = minLat + (maxLat - minLat) / 2;
        center.longitude = minLon + (maxLon - minLon) / 2;
        
        double latDelta = maxLat - minLat;
        double lonDelta = maxLon - minLon; 
        
        MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
        
        [self setRegion:MKCoordinateRegionMake(center, span)];

    } else {
        
        [self setRegion:MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN)];
    }
    
}

- (void)dealloc {
    [_events release];
    _events = nil;
    [super dealloc];
}

@end
