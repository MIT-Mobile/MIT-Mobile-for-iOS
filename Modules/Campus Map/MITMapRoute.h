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

@optional

// array of MKAnnotations that are to be included with this route
- (NSArray *)annotations;

@end

@interface MITGenericMapRoute : NSObject <MITMapRoute> {
    NSArray *pathLocations;
    UIColor *fillColor;
    UIColor *strokeColor;
    CGFloat lineWidth;
}

@property (nonatomic, retain) NSArray *pathLocations;
@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *strokeColor;
@property (nonatomic) CGFloat lineWidth;

@end
