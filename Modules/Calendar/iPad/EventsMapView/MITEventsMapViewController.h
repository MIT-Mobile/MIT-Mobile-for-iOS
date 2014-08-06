
#import <UIKit/UIKit.h>

@interface MITEventsMapViewController : UIViewController

- (void)showCurrentLocation;
- (void)updateMapWithEvents:(NSArray *)eventsArray; // [MITCalendarsEvent]

@end
