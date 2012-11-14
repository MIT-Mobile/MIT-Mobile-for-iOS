#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MGSMapCoordinate : NSObject <NSCopying, NSCoding>
@property (nonatomic,readonly,assign) double longitude;
@property (nonatomic,readonly,assign) double x;

@property (nonatomic,readonly,assign) double latitude;
@property (nonatomic,readonly,assign) double y;

- (id)initWithLocation:(CLLocationCoordinate2D)location;
- (id)initWithLongitude:(double)longitude latitude:(double)latitude;
- (id)initWithX:(double)x y:(double)y;

- (CLLocationCoordinate2D)wgs84Location;

@end
