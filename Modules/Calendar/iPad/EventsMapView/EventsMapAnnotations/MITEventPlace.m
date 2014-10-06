
#import "MITEventPlace.h"
#import "MITCalendarsEvent.h"

@implementation MITEventPlace

- (instancetype)initWithCalendarsEvent:(MITCalendarsEvent *)calendarsEvent
{
    self = [super init];
    if(self)
    {
        _calendarsEvent = calendarsEvent;
        if (calendarsEvent.location) {
            NSArray *locationCoordinates = calendarsEvent.location.coordinates;
            if (locationCoordinates) {
                self.coordinate = CLLocationCoordinate2DMake([[locationCoordinates firstObject] doubleValue], [[locationCoordinates lastObject] doubleValue]);
            } else {
                return nil;
            }
            
        } else {
            return nil;
        }
    }
    return self;
}

@end
