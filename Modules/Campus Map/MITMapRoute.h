#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol MITMapRoute <NSObject>

@required

// array of CLLocations making up the path of this route
// TODO: CLLocation might be overkill if we only need the associated CLLocationCoordinate2D
- (NSArray *)pathLocations;

// wrappers around MKPolyline properties
- (UIColor *)fillColor;
- (UIColor *)strokeColor;
- (CGFloat)lineWidth;
- (NSArray *)lineDashPattern;

@optional

// array of MKAnnotations that are to be included with this route
- (NSArray *)annotations;

@end

@interface MITGenericMapRoute : NSObject <MITMapRoute>

@property (nonatomic, copy) NSArray *pathLocations;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, copy) NSArray *lineDashPattern;
@property (nonatomic) CGFloat lineWidth;

@end
