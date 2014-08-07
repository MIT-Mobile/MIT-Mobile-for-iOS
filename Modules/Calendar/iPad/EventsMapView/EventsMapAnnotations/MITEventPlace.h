
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITCalendarsEvent;

@interface MITEventPlace : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (strong, nonatomic, readonly) MITCalendarsEvent *calendarsEvent;
- (instancetype)initWithCalendarsEvent:(MITCalendarsEvent *)calendarsEvent;

@property (nonatomic) NSInteger displayNumber;

@end
