#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class MITCalendarEvent;

@interface CalendarEventMapAnnotation : NSObject <MKAnnotation>
@property (nonatomic, weak) MITCalendarEvent *event;

- (id)initWithEvent:(MITCalendarEvent *)anEvent;
- (NSInteger)eventID;
- (NSString *)subtitle;
- (NSString *)title;

@end
