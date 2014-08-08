#import <UIKit/UIKit.h>

@class MITCalendarsEvent;

@interface MITEventsMapViewController : UIViewController

- (void)showCurrentLocation;
- (void)updateMapWithEvents:(NSArray *)eventsArray; // [MITCalendarsEvent]
- (BOOL)canSelectEvent:(MITCalendarsEvent *)event;
- (void)selectEvent:(MITCalendarsEvent *)event;

@end
