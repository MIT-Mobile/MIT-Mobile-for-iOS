#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITToursStop.h"

@interface MITToursStopAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong, readonly) MITToursStop *stop;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;

- (instancetype)initWithStop:(MITToursStop *)stop;

@end
